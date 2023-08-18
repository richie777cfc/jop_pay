# cordova-plugin-upi
Cordova plugin to pay via UPI supported apps via intent based

### Supported Platform:
* Android

### Installations:
> cordova plugin add https://github.com/richie777cfc/jop_pay

After installation, the upi plugin would be avilable in "window" object.

### Methods:
* Fetch UPI supported apps.
```js
pspAppsResponseList = function(apps) {
    console.log("UPI supported apps" + JSON.stringify(apps));
}
failureCallback = function(err) {
    console.log("Issue in fetching UPI supported apps " + err);
}

function getPspAppsList() {
    window["UPI"].supportedApps(pspAppsResponseList, failureCallback);
}
```
* Start a transaction
you can start a transaction either by passing upistring or parsed value as given below.

```js
appid = "com.google.android.apps.nbu.paisa.user"

upistring = "upi://pay?mc=4121&pa=jptest.npysvjimjztqaq@yestransact&pn=BUS1007&tr=unPQB2ZFnzvrT2mvfGHH&am=1";

paymentstring = appid + "|" + upistring;

function launchPspAppForUpiPayment(upivalue) {
    var appConfig = upivalue.split("|")[0]
    var upiconfig = upivalue.split("|")[1]
    window["UPI"].acceptPayment(upiconfig, appConfig, launchPspAppForUpiPaymentSuccess, launchPspAppForUpiPaymentFailure);
}

launchPspAppForUpiPaymentSuccess = function(apps) {
    console.log("Payment success");
}
launchPspAppForUpiPaymentFailure = function(err) {
    console.log("Payment failed");
}

launchPspAppForUpiPayment(paymentstring);
```

### Responses:

Sample response of successful payment
```json
{
  "ApprovalRefNo": "932413452",
  "Status": "SUCCESS",
  "message": "txnId=764900774.690841&responseCode=00&Status=SUCCESS&txnRef=417855597.31908274&ApprovalRefNo=932413452",
  "responseCode": "00",
  "status": "SUCCESS",
  "txnId": "764900774.690841",
  "txnRef": "417855597.31908274",
  "appId": "com.phonepe.app.preprod",
  "appName": "PhonePe Preprod",
}
```

Sample response of failure payment
```json
{
  "Status": "FAILURE",
  "message": "txnId=901818401.3087038&responseCode=ZD&Status=FAILURE&txnRef=654595701.7025663",
  "responseCode": "ZD",
  "status": "FAILURE",
  "txnId": "901818401.3087038",
  "txnRef": "654595701.7025663",
  "appId": "com.phonepe.app.preprod",
  "appName": "PhonePe Preprod",
}
```

### InAppBrowser integration:

* Integration with InAppBrowser
```js
// Code for opening the InAppBrowser. Use below options. URL to be replaced with relevant URL.
var options = "closebuttoncolor=#000000,lefttoright=yes,hideurlbar=yes,fullscreen=yes,hardwareback=no,toolbarcolor=#145a7b,zoom=no,useWideViewPort=no,hidenavigationbuttons=yes,footer=no,message=Hello,toolbar=no,location=no";
let browser = cordova.InAppBrowser.open('https://www.google.com/','_blank', options)
browser.addEventListener('message', messCalls); //Event listener for messages.

function messCalls(params) {
  if (params.data.eventtype && params.data.eventtype == "webjs") {
    eval(params.data.type + "()");
  }
}


//Sample code for PSP app list
pspAppsResponseList = function(apps) {
    console.log("UPI supported apps" + JSON.stringify(apps));
    // Below code is to send the response back to the InAppBrowser URL.
    browser.executeScript({
          code: "pspAppsResponseList("+JSON.stringify(apps)+")"});
}

failureCallback = function(err) {
    alert("Issue in fetching UPI supported apps " + err);
}

function getPspAppsList() {
    window["UPI"].supportedApps(pspAppsResponseList, failureCallback);
}

```

* Sending message from InAppBrowser
```js
// Sample request format which will need to be written in inappbrowser url.
// eventtype will be webjs which client end needs to read for function execution
function getPspAppsList() {
  var messageObj = {eventtype: "webjs", type: "getPspAppsList"};
  var stringifiedMessageObj = JSON.stringify(messageObj);
  window.webkit.messageHandlers.cordova_iab.postMessage(stringifiedMessageObj);
}

//Response to be sent to client in below method.
function pspAppsResponseList(pspApps) {
  console.log(pspApps)
}

```

### Release Notes:
# 1.0.0:
 Initial Release of cordova plugin for upi transaction
