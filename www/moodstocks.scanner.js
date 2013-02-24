/**
 * Moodstocks scanner
 */

var MoodstocksScanner = function () {
};

/****************************/
/* define available methods */
/****************************/

MoodstocksScanner.prototype.scan = function(success, error) {
  console.log('call moodstocksScanner.scan');

  if (typeof success != 'function') {
    console.log('MoodstocksScanner.scan failure : success callback is not a function');
  }

  if (typeof error != 'function') {
    console.log('MoodstocksScanner.scan failure : error callback is not a function');
  }

  cordova.exec(success, error, 'MoodstocksScanner', 'scan', []);
};

/*********************************************/
/* set scanner into global plugins namespace */
/*********************************************/
if(!window.plugins) {
    window.plugins = {};
}
if (!window.plugins.moodstocksScanner) {
    window.plugins.moodstocksScanner = new MoodstocksScanner();
}
