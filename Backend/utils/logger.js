const log4js = require("log4js")

// Define different configurations for development and production
const devConfig = {
    appenders: {
        out: {
            type: "stdout",
        },
    },
    categories: {
        default: {
            appenders: ["out"],
            level: "debug",
        },
    },
}

const prodConfig = {
    appenders: {
        out: {
            type: "stdout",
        },
        everything: {
            type: "file",
            filename: `logs/app.log`,
            // pattern: "yyyy-MM-dd-hh-mm",
            compress: true,
            //keepFileExt: true,
            daysToKeep: 7,
        },
        emergencies: {
            type: "file",
            filename: `logs/panic.log`,
            // pattern: "yyyy-MM-dd-hh-mm",
            compress: true,
            // keepFileExt: true,
            daysToKeep: 7,
        },
        "just-errors": {
            type: "logLevelFilter",
            appender: "emergencies",
            level: "error",
        },
    },
    categories: {
        default: { appenders: ["out", "just-errors", "everything"], level: "debug" },
    },
}




// ✅ This will now get the correct value
const environment = process.env.NODE_ENV || "development";
console.log("🌐 Logger initialized in:", environment);

const config = environment === "production" ? prodConfig : devConfig;
log4js.configure(config);

const logger = log4js.getLogger();

// If in production, override global console methods to use our logger (automatically saving to files)
// while still printing to stdout (Putty) via the 'out' appender.
if (environment === "production") {
    console.log = (...args) => logger.info(...args);
    console.error = (...args) => logger.error(...args);
    console.warn = (...args) => logger.warn(...args);
}

module.exports = logger;
