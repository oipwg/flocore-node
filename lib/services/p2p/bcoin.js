'use strict';

var index = require('../../');
var log = index.log;
var bcoin = require('fcoin');
// var bzmq = require('bzmq');

var Bcoin = function(options) {
  this._config = this._getConfig(options);
};

Bcoin.prototype.start = function(callback) {
  this._bcoin = new bcoin.FullNode(this._config);

  log.info('Starting fcoin FullNode...');

  this._bcoin.open().then(() => {
    this._bcoin.connect().then(() => {
      this._bcoin.startSync();
      callback();
    });
  });
};

Bcoin.prototype.stop = function(callback) {
  if (this._bcoin) {
    this._bcoin.close().then(() => {
      log.info("fcoin shutdown");
      callback();
    }).catch((err) => {
      log.error("Error shutting down fcoin: ", err);
      callback(err);
    });
  } else {
    callback();
  }
};

// --- privates

Bcoin.prototype._getConfig = function(options) {
  var config = {
    network: options.network || 'main',
    port: options.port,

    logFile: true,
    logConsole: true,
    logLevel: 'info',

    // indexTx: true,
    // indexAddress: true,

    checkpoints: true,
    memory: false,
    workers: true,
    listen: true
  };
  if (options.prefix) {
    config.prefix = options.prefix;
  }
  return config;
};

module.exports = Bcoin;
