const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

/**
 * Automatically set Stripe payout schedule to weekly on Mondays
 * Call this function whenever a kitchen's stripeAccountId is added or updated
 * 
 * ⭐ SMART UPDATE: Checks current schedule first to avoid unnecessary API calls
 * 
 * @param {string} stripeAccountId - The Stripe Connect account ID
 * @param {object} options - Payout schedule options
 * @returns {Promise<object>} - Updated account info
 */
async function setWeeklyPayoutSchedule(stripeAccountId, options = {}) {
    const {
        interval = 'weekly',
        weeklyAnchor = 'monday'
    } = options;

    try {
        // ⭐ First, check current payout schedule to avoid unnecessary updates
        const account = await stripe.accounts.retrieve(stripeAccountId);

        const currentSchedule = account.settings?.payouts?.schedule;
        const isAlreadyConfigured =
            currentSchedule?.interval === interval &&
            (interval !== 'weekly' || currentSchedule?.weekly_anchor === weeklyAnchor);

        if (isAlreadyConfigured) {
            console.log(`✅ [STRIPE] Payout schedule already set for ${stripeAccountId} - skipping update`);
            return {
                success: true,
                accountId: stripeAccountId,
                alreadyConfigured: true,
                payoutSchedule: {
                    interval: currentSchedule.interval,
                    ...(interval === 'weekly' && { weeklyAnchor: currentSchedule.weekly_anchor })
                }
            };
        }

        // ⭐ Update only if not already configured
        const updatedAccount = await stripe.accounts.update(stripeAccountId, {
            settings: {
                payouts: {
                    schedule: {
                        interval: interval,
                        ...(interval === 'weekly' && { weekly_anchor: weeklyAnchor })
                    }
                }
            }
        });

        console.log(`✅ [STRIPE] Set payout schedule for ${stripeAccountId} to ${interval}${interval === 'weekly' ? ` on ${weeklyAnchor}s` : ''}`);

        return {
            success: true,
            accountId: stripeAccountId,
            alreadyConfigured: false,
            payoutSchedule: {
                interval,
                ...(interval === 'weekly' && { weeklyAnchor })
            }
        };

    } catch (error) {
        console.error(`❌ [STRIPE] Failed to set payout schedule for ${stripeAccountId}:`, error.message);

        return {
            success: false,
            accountId: stripeAccountId,
            error: error.message
        };
    }
}

/**
 * Bulk update payout schedules for multiple Stripe accounts
 * 
 * @param {Array<string>} stripeAccountIds - Array of Stripe account IDs
 * @param {object} options - Payout schedule options
 * @returns {Promise<object>} - Results summary
 */
async function bulkSetPayoutSchedules(stripeAccountIds, options = {}) {
    const results = {
        success: [],
        failed: [],
        skipped: []
    };

    for (const accountId of stripeAccountIds) {
        const result = await setWeeklyPayoutSchedule(accountId, options);

        if (result.success) {
            if (result.alreadyConfigured) {
                results.skipped.push(accountId);
            } else {
                results.success.push(accountId);
            }
        } else {
            results.failed.push({
                accountId,
                error: result.error
            });
        }
    }

    console.log(`\n📊 [STRIPE] Payout Schedule Update Summary:`);
    console.log(`   ✅ Updated: ${results.success.length}`);
    console.log(`   ⏭️  Skipped (already configured): ${results.skipped.length}`);
    console.log(`   ❌ Failed: ${results.failed.length}`);

    return results;
}

module.exports = {
    setWeeklyPayoutSchedule,
    bulkSetPayoutSchedules
};
