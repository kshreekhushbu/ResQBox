const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
const prisma = require('./prisma');

/**
 * Create or get Stripe customer for a user
 * @param {number} userId - User ID
 * @param {string} email - User email
 * @param {string} name - User name
 * @returns {Promise<string>} Stripe customer ID
 */
async function getOrCreateStripeCustomer(userId, email, name) {
    try {
        // Check if user already has a Stripe customer ID
        const user = await prisma.user.findUnique({
            where: { userId: Number(userId) },
            select: { stripeCustomerId: true, email: true, name: true }
        });

        if (user.stripeCustomerId) {
            return user.stripeCustomerId;
        }

        // Create new Stripe customer
        const customer = await stripe.customers.create({
            email: email || user.email,
            name: name || user.name || 'Guest User',
            metadata: {
                userId: userId.toString()
            }
        });

        // Save customer ID to database
        await prisma.user.update({
            where: { userId: Number(userId) },
            data: { stripeCustomerId: customer.id }
        });

        console.log(`✅ Created Stripe customer ${customer.id} for user ${userId}`);
        return customer.id;
    } catch (error) {
        console.error('❌ Error creating Stripe customer:', error);
        throw error;
    }
}

/**
 * Create SetupIntent for saving a card (NO CHARGE)
 * This is used when user wants to add a new card
 * @param {number} userId - User ID
 * @returns {Promise<Object>} SetupIntent with client secret
 */
async function createSetupIntent(userId) {
    try {
        // Get user
        const user = await prisma.user.findUnique({
            where: { userId: Number(userId) },
            select: { stripeCustomerId: true, email: true, name: true }
        });

        if (!user) {
            throw new Error('User not found');
        }

        // Get or create Stripe customer
        const customerId = user.stripeCustomerId || await getOrCreateStripeCustomer(userId, user.email, user.name);

        // Create SetupIntent
        const setupIntent = await stripe.setupIntents.create({
            customer: customerId,
            payment_method_types: ['card'],
            usage: 'off_session', // Allows future auto payments
            metadata: {
                userId: userId.toString()
            }
        });

        console.log(`✅ Created SetupIntent ${setupIntent.id} for user ${userId}`);

        return {
            clientSecret: setupIntent.client_secret,
            setupIntentId: setupIntent.id
        };
    } catch (error) {
        console.error('❌ Error creating SetupIntent:', error);
        throw error;
    }
}

/**
 * Save payment method after SetupIntent confirmation
 * This is called after the frontend confirms the SetupIntent
 * @param {number} userId - User ID
 * @param {string} paymentMethodId - Stripe payment method ID (from confirmed SetupIntent)
 * @param {boolean} setAsDefault - Set as default payment method
 * @returns {Promise<Object>} Saved card object
 */
async function savePaymentMethodFromSetupIntent(userId, paymentMethodId, setAsDefault = false) {
    try {
        // Get user
        const user = await prisma.user.findUnique({
            where: { userId: Number(userId) },
            select: { stripeCustomerId: true }
        });

        if (!user || !user.stripeCustomerId) {
            throw new Error('User does not have a Stripe customer ID');
        }

        // Retrieve payment method details from Stripe
        const paymentMethod = await stripe.paymentMethods.retrieve(paymentMethodId);

        // Verify it's attached to the customer
        if (paymentMethod.customer !== user.stripeCustomerId) {
            throw new Error('Payment method not attached to customer');
        }

        // Check if card already exists (by fingerprint)
        const existingCard = await prisma.savedCard.findFirst({
            where: {
                userId: Number(userId),
                cardFingerprint: paymentMethod.card.fingerprint
            }
        });

        if (existingCard) {
            throw new Error('This card is already saved');
        }

        // If setting as default, unset other default cards
        if (setAsDefault) {
            await prisma.savedCard.updateMany({
                where: { userId: Number(userId), isDefault: true },
                data: { isDefault: false }
            });

            // Set as default in Stripe
            await stripe.customers.update(user.stripeCustomerId, {
                invoice_settings: {
                    default_payment_method: paymentMethodId
                }
            });
        }

        // Save card to database
        const savedCard = await prisma.savedCard.create({
            data: {
                userId: Number(userId),
                stripePaymentMethodId: paymentMethodId,
                cardBrand: paymentMethod.card.brand,
                cardLast4: paymentMethod.card.last4,
                cardExpMonth: paymentMethod.card.exp_month,
                cardExpYear: paymentMethod.card.exp_year,
                cardHolderName: paymentMethod.billing_details?.name || null,
                cardFingerprint: paymentMethod.card.fingerprint,
                isDefault: setAsDefault
            }
        });

        console.log(`✅ Saved payment method ${paymentMethodId} for user ${userId}`);
        return savedCard;
    } catch (error) {
        console.error('❌ Error saving payment method:', error);
        throw error;
    }
}

/**
 * Get all saved cards for a user (directly from Stripe)
 * @param {number} userId - User ID
 * @param {boolean} fromDatabase - If true, fetch from database; if false, fetch from Stripe
 * @returns {Promise<Array>} Array of saved cards
 */
async function getSavedCards(userId, fromDatabase = true) {
    try {
        if (fromDatabase) {
            // Fetch from database (faster)
            const cards = await prisma.savedCard.findMany({
                where: { userId: Number(userId) },
                orderBy: [
                    { isDefault: 'desc' },
                    { createdAt: 'desc' }
                ]
            });
            return cards;
        } else {
            // Fetch from Stripe (always up-to-date)
            const user = await prisma.user.findUnique({
                where: { userId: Number(userId) },
                select: { stripeCustomerId: true }
            });

            if (!user || !user.stripeCustomerId) {
                return [];
            }

            const paymentMethods = await stripe.paymentMethods.list({
                customer: user.stripeCustomerId,
                type: 'card'
            });

            // Get default payment method
            const customer = await stripe.customers.retrieve(user.stripeCustomerId);
            const defaultPaymentMethodId = customer.invoice_settings?.default_payment_method;

            return paymentMethods.data.map(pm => ({
                paymentMethodId: pm.id,
                cardBrand: pm.card.brand,
                cardLast4: pm.card.last4,
                cardExpMonth: pm.card.exp_month,
                cardExpYear: pm.card.exp_year,
                cardHolderName: pm.billing_details?.name,
                isDefault: pm.id === defaultPaymentMethodId
            }));
        }
    } catch (error) {
        console.error('❌ Error fetching saved cards:', error);
        throw error;
    }
}

/**
 * Delete a saved card
 * @param {number} userId - User ID
 * @param {number} cardId - Card ID (database ID)
 * @returns {Promise<void>}
 */
async function deleteSavedCard(userId, cardId) {
    try {
        // Get card
        const card = await prisma.savedCard.findFirst({
            where: {
                cardId: Number(cardId),
                userId: Number(userId)
            }
        });

        if (!card) {
            throw new Error('Card not found');
        }

        // Detach from Stripe customer
        try {
            await stripe.paymentMethods.detach(card.stripePaymentMethodId);
        } catch (stripeError) {
            console.warn('⚠️ Could not detach payment method from Stripe:', stripeError.message);
            // Continue with database deletion even if Stripe detach fails
        }

        // Delete from database
        await prisma.savedCard.delete({
            where: { cardId: Number(cardId) }
        });

        // If this was the default card, set another card as default
        if (card.isDefault) {
            const nextCard = await prisma.savedCard.findFirst({
                where: { userId: Number(userId) },
                orderBy: { createdAt: 'desc' }
            });

            if (nextCard) {
                await setDefaultCard(userId, nextCard.cardId);
            }
        }

        console.log(`✅ Deleted card ${cardId} for user ${userId}`);
    } catch (error) {
        console.error('❌ Error deleting saved card:', error);
        throw error;
    }
}

/**
 * Set a card as default
 * @param {number} userId - User ID
 * @param {number} cardId - Card ID (database ID)
 * @returns {Promise<Object>} Updated card
 */
async function setDefaultCard(userId, cardId) {
    try {
        // Get card
        const card = await prisma.savedCard.findFirst({
            where: {
                cardId: Number(cardId),
                userId: Number(userId)
            }
        });

        if (!card) {
            throw new Error('Card not found');
        }

        // Get user's Stripe customer ID
        const user = await prisma.user.findUnique({
            where: { userId: Number(userId) },
            select: { stripeCustomerId: true }
        });

        // Unset all default cards
        await prisma.savedCard.updateMany({
            where: { userId: Number(userId), isDefault: true },
            data: { isDefault: false }
        });

        // Set new default card
        const updatedCard = await prisma.savedCard.update({
            where: { cardId: Number(cardId) },
            data: { isDefault: true }
        });

        // Update default in Stripe
        if (user.stripeCustomerId) {
            await stripe.customers.update(user.stripeCustomerId, {
                invoice_settings: {
                    default_payment_method: card.stripePaymentMethodId
                }
            });
        }

        console.log(`✅ Set card ${cardId} as default for user ${userId}`);
        return updatedCard;
    } 
    catch (error) {
        console.error('❌ Error setting default card:', error);
        throw error;
    }
}

/**
 * Create payment intent with saved card
 * @param {number} userId - User ID
 * @param {number} amount - Amount in dollars (will be converted to cents)
 * @param {number} cardId - Card ID (optional, uses default if not provided)
 * @param {Object} metadata - Additional metadata
 * @returns {Promise<Object>} Payment intent
 */
async function createPaymentIntentWithSavedCard(userId, amount, cardId = null, metadata = {}) {
    try {
        // Get user
        const user = await prisma.user.findUnique({
            where: { userId: Number(userId) },
            select: { stripeCustomerId: true }
        });

        if (!user || !user.stripeCustomerId) {
            throw new Error('User does not have a Stripe customer ID');
        }

        // Get card
        let card;
        if (cardId) {
            card = await prisma.savedCard.findFirst({
                where: {
                    cardId: Number(cardId),
                    userId: Number(userId)
                }
            });
        } else {
            // Use default card
            card = await prisma.savedCard.findFirst({
                where: {
                    userId: Number(userId),
                    isDefault: true
                }
            });
        }

        if (!card) {
            throw new Error('No saved card found');
        }

        // Create payment intent
        const paymentIntent = await stripe.paymentIntents.create({
            amount: Math.round(amount * 100), // Convert to cents
            currency: 'aud', // Adjust based on your currency
            customer: user.stripeCustomerId,
            payment_method: card.stripePaymentMethodId,
            off_session: true,
            confirm: true,
            metadata: {
                userId: userId.toString(),
                ...metadata
            }
        });

        console.log(`✅ Created payment intent ${paymentIntent.id} for user ${userId}`);
        return paymentIntent;
    } catch (error) {
        console.error('❌ Error creating payment intent with saved card:', error);
        throw error;
    }
}

module.exports = {
    getOrCreateStripeCustomer,
    createSetupIntent,
    savePaymentMethodFromSetupIntent,
    getSavedCards,
    deleteSavedCard,
    setDefaultCard,
    createPaymentIntentWithSavedCard
};
