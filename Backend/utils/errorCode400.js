const AppErrors = require("./appErrors");

class Api400Error extends AppErrors {
  constructor(
    name,
    statusCode = 400,
    isOperational = true,
    description = "Bad Request"
  ) {
    super(name, statusCode, isOperational, description);
  }
}

module.exports = Api400Error;
