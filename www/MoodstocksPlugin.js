var MoodstocksPlugin = {

    // Load scanner with given api key & api secret pair
    open: function(success, fail) {
        if (!fail) {
            fail = function() {}
        }

        if (!success) {
            success = function() {}
        }

        if (typeof fail != "function") {
            console.log("fail callback parameter must be a function");
            return;
        }

        if (typeof success != "function") {
            console.log("success callback parameter must be a function");
            return;
        }

        return cordova.exec(success, fail, "MoodstocksPlugin","open", []);
    },

    // Sync the cache
    sync: function(isReady, inProgress, finished, fail) {
        function successWrapper(result) {
            switch(result.status) {
                case 1:
                    isReady.call(null);
                    break;
                case 2:
                    inProgress.call(null, result.progress);
                    break;
                case 3:
                    finished.call(null);
                    break;
                case 0:
                    fail.call(null, result.message);
                    break;
                default:
                    break;
            }
        }

        if (!isReady) {
            isReady = function() {}
        }

        if (!inProgress) {
            inProgress = function() {}
        }

        if (!finished) {
            finished = function() {}
        }

        if (!fail) {
            fail = function() {}
        }

        if (typeof isReady != "function") {
            console.log("isReady callback parameter must be a function");
            return;
        }

        if (typeof inProgress != "function") {
            console.log("inProgress callback parameter must be a function");
            return;
        }

        if (typeof finished != "function") {
            console.log("finished callback parameter must be a function");
            return;
        }

        if (typeof fail != "function") {
            console.log("fail callback parameter must be a function");
            return;
        }

        return cordova.exec(successWrapper, fail, "MoodstocksPlugin", "sync", []);
    },

    // Launch the scanner
    scan: function(success, fail, scanOptions) {
        // Scan formats
        var scanFormats = {
            ean8: 1 << 0,                /* EAN8 linear barcode */
            ean13: 1 << 1,               /* EAN13 linear barcode */
            qrcode: 1 << 2,              /* QR Code 2D barcode */
            dmtx: 1 << 3,                /* Datamatrix 2D barcode */
            image: 1 << 31               /* Image match */
        }

        var resultFormats = {
            none: "None",
            ean8: "EAN8",
            ean13: "EAN13",
            qrcode: "QR CODE",
            dmtx: "DATA MATRIX",
            image: "IMAGE"
        }

        // Wrap the success callback with scan result's type and value
        function successWrapper(result) {
            for (strFormat in scanFormats) {
                if (result.format === scanFormats[strFormat]) {
                    success.call(null, resultFormats[strFormat], result.value);
                    return;
                }
            }
            success.call(null, resultFormats.none, null);
        }

        if (!fail) {
            fail = function() {}
        }

        if (!success) {
            success = function() {}
        }

        if (!scanOptions) {
            scanOptions = {image: true};
        }

        if (typeof fail != "function") {
            console.log("fail callback parameter must be a function");
            return;
        }

        if (typeof success != "function") {
            console.log("success callback parameter must be a function");
            return;
        }

        var formats = 0;
        // Set the scan options according to the user choices
        for (strFormat in scanFormats) {
            if (scanOptions[strFormat]) {
                formats |= scanFormats[strFormat];
            }
        }

        return cordova.exec(successWrapper, fail, "MoodstocksPlugin", "scan", [formats]);
    }

}
