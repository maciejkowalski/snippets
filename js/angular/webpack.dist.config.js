var webpack = require('webpack');
var path    = require('path');
var config  = require('./webpack.config');

var appConfigGlobals = require('./client/app/config.js')

var CopyWebpackPlugin = require('copy-webpack-plugin')

config.output = {
  filename: '[name].bundle.js',
  publicPath: global.PREFIX,
  path: path.resolve(__dirname, global.WEBPACK_DIST)
};

config.plugins = config.plugins.concat([

  // Reduces bundles total size
  new webpack.optimize.UglifyJsPlugin({
    mangle: {

      // You can specify all variables that should not be mangled.
      // For example if your vendor dependency doesn't use modules
      // and relies on global variables. Most of angular modules relies on
      // angular global variable, so we should keep it unchanged
      except: ['$super', '$', 'exports', 'require', 'angular']
    }
  }),

  new CopyWebpackPlugin([
            // {output}/to/file.txt
            { from: 'php/get_data.php', to: 'get_data.php' },
            { from: 'php/send_email.php', to: 'send_email.php' }
  ])
]);

module.exports = config;
