const logger = require("../utils/logger");

/* 
**
 developement errors
 */

const sendErrorDev = (err, res) => {
  // if err is operational ,trusted message : send message to client
  if (err.isOperational) {
    res.status(err.statusCode).json({
      status: 0,
      message: err.name,
      error: err.message
    });
  } else {
    /* 
      **
      programming or unknown errors : 
      don't leak details to the client
       */
    res.status(err.statusCode).json({
      status: 0,
      message: "Somthing went wrong."
    });
  }
};

/* 
  **
  production errors
   */
const sendErrorPro = (err, res) => {
  // if err is operational ,trusted message : send message to client
  if (err.isOperational) {
    res.status(err.statusCode).json({
      status: 0,
      message: err.name,
      error: err.message
    });
  } else {
    /* 
      **
      programming or unknown errors : 
      don't leak details to the client
       */
    res.status(err.statusCode).json({
      status: 0,
      message: "Somthing went wrong."
    });
  }
};

const jwtTokenError = (err, res) => {
  return res.status(err.statusCode).json({
    status: 0,
    message: "Your session expired please login again!",
    isTokenExpired: 1
  });
};

/*
  ** 
  GLOBAL ERROR HANDLER FUNCTION
  */

module.exports = (err, req, res, next) => {
  console.log("err", err);
  logger.error("err", err);

  err.statusCode = err.statusCode || 500;

  if (process.env.NODE_ENV === "development") {
    if (err.name === "JsonWebTokenError") jwtTokenError(err, res);
    if (err.name === "TokenExpiredError") jwtTokenError(err, res);

    sendErrorDev(err, res);
  } else if (process.env.NODE_ENV === "production") {
    if (err.name === "JsonWebTokenError") jwtTokenError(err, res);
    if (err.name === "TokenExpiredError") jwtTokenError(err, res);

    sendErrorPro(err, res);
  }
};
