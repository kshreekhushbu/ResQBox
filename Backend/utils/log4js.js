const log4js = require("log4js")
const obj = require("./logger")

// Load the log4js configuration file
log4js.configure(obj)

// Get the current environment
const environment = process.env.NODE_ENV

// Get the logger based on the environment
const logger = log4js.getLogger(environment)

module.exports = logger
