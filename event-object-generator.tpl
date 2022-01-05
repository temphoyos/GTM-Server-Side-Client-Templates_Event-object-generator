___INFO___

{
  "type": "CLIENT",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "Event object generator",
  "brand": {
    "id": "brand_dummy",
    "displayName": ""
  },
  "description": "This client accepts any incoming http GET or POST request and generates an event object,",
  "containerContexts": [
    "SERVER"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "allowedOrigins",
    "displayName": "Origins allowed to send http requests to this end point. Do not include https:// protocol.",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ],
    "help": "If including more than one origin, separate with commas: origin1.com,origin2.com"
  },
  {
    "type": "TEXT",
    "name": "requestPath",
    "displayName": "Http request path to be claimed by the client",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "TEXT",
    "name": "eventQueryParam",
    "displayName": "Query param containing the event name or type. If the value doesn\u0027t match with the query param, a \u0027no_event\u0027 event will be generated.",
    "simpleValueType": true,
    "help": "In the following example, the query param containing the event name would be \u0027en\u0027 https://example.com?en\u003dpage_view",
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ]
  },
  {
    "type": "CHECKBOX",
    "name": "cookieCheckbox",
    "checkboxText": "Include cookie value in event object?",
    "simpleValueType": true,
    "subParams": [
      {
        "type": "TEXT",
        "name": "cookieName",
        "displayName": "Name of the cookie to be included in the eventObject",
        "simpleValueType": true,
        "enablingConditions": [
          {
            "paramName": "cookieCheckbox",
            "paramValue": true,
            "type": "EQUALS"
          }
        ],
        "valueValidators": [
          {
            "type": "NON_EMPTY"
          },
          {
            "type": "NON_EMPTY"
          }
        ],
        "help": "Cookies must be set to the same domain of the tagging server. If including more than one cookie, separate names with commas: oneCookie, anotherCookie..."
      }
    ]
  },
  {
    "type": "CHECKBOX",
    "name": "anonymizeCheckbox",
    "checkboxText": "Anonymize event object",
    "simpleValueType": true,
    "help": "If you check this checkbox, the user\u0027s IP and user agent will not be included in the event object"
  }
]


___SANDBOXED_JS_FOR_SERVER___

//API's needed to make this client template work
const claimRequest = require('claimRequest');
const getCookieValues = require('getCookieValues');
const getRequestBody = require('getRequestBody');
const getRequestHeader = require('getRequestHeader');
const getRequestMethod = require('getRequestMethod');
const getRequestPath = require('getRequestPath');
const getRequestQueryParameters = require('getRequestQueryParameters');
const JSON = require('JSON');
const logToConsole = require('logToConsole');
const returnResponse = require('returnResponse');
const runContainer = require('runContainer');
const setResponseHeader = require('setResponseHeader');
const setResponseStatus = require('setResponseStatus');

//API's saved for reuse
const requestBody = getRequestBody();
const requestMethod = getRequestMethod();
const requestPath = getRequestPath();
const requestQueryParameters = getRequestQueryParameters();

//Code starts here

//Logic to check if incoming request origin is allowed to be claimed
let allowedOrigins = data.allowedOrigins.toLowerCase().split(',');
let admitedRequest;

allowedOrigins.forEach((value,index,array)=>{
  
  array[index]= 'https://' + value;
  
});

allowedOrigins.forEach((value)=>{
  
  if(getRequestHeader("origin") === value){
    
    admitedRequest = true;
  } 
});

if(requestPath === data.requestPath && admitedRequest === true){

  claimRequest();
  
  //Code logic to be executed if http request type is GET
  if(requestMethod === 'GET'){
    
    //Set response headers to avoid CORS
    setResponseHeader("access-control-allow-credentials", "true");
    setResponseHeader("access-control-allow-origin", getRequestHeader("origin"));
    
    //Generate an object from the request url's query parameters
    let eventObject = requestQueryParameters;
    
    //Generate an event_name property for within eventObject to run the virtual cntainer instance    
    eventObject.event_name = requestQueryParameters[data.eventQueryParam] ? requestQueryParameters[data.eventQueryParam] : 'no_event';
    
    //Set aditional properties within eventObject from the incoming http request headers
    eventObject.page_referrer = getRequestHeader('referer');
    eventObject['x-params-country'] = getRequestHeader('X-Appengine-Country');
    eventObject['x-params-city'] = getRequestHeader('X-Appengine-City');
    //Uncoment the following line of code and configure to include any additional properties to eventObject from the desired request headers. Must include one line per requesHeader
    //eventObject[propertyName] = getRequestHeader('Header name');
    
    //Set aditional properties within eventObject from the incoming http request selected cookies. These cookies must be set at the same domain as the server tagging server
    if(data.cookieCheckbox){
      
      let cookies = data.cookieName.split(',');
      
      for(let i = 0; i < cookies.length; i++){
        
        eventObject['x-params-'+ cookies[i]+ '-cookie-value'] = getCookieValues(cookies[i]).toString();
      
      }
            
    }
     
    //If request request anonimization checkbox not checked, include user ip and user agent as properties of eventObject
    if(!data.anonymizeCheckbox){
    
      eventObject['x-params-user-Ip'] = getRequestHeader('X-Appengine-User-Ip');
      eventObject['x-params-user-agent'] = getRequestHeader('User-Agent');
      
    }
    
    //Generate a new object (containerEventParams) from eventObject (excluding the  eventObject[data.eventQueryParam] property that was used to generate the eventObject[event_name] property. This way we avoid object property duplication. 
    let containerEventParams = {};
    
    for(const property in eventObject ){
    
      if(property !== data.eventQueryParam){
        
        containerEventParams[property] = eventObject[property];
      
      }
    
    }
    
   //Run container     
   runContainer(containerEventParams, () => returnResponse());
  
  }
  
 //Code logic to be executed if http request type is POST
 else if(requestMethod === 'POST'){
   
    //Set response headers to avoid CORS
    setResponseHeader("access-control-allow-credentials", "true");
    setResponseHeader("access-control-allow-origin", getRequestHeader("origin"));
   
   //Code logic to be executed if POST http request includes a request body 
   if(requestBody){
     
     //Parse the request body JSON into an object
     const body = JSON.parse(requestBody);
     
     //Generate an object from the request url's query parameters
     let eventObject = requestQueryParameters;
     
     //Include the request body properties and values into eventObject
     for(const property in body){
     
       eventObject[property] = body[property];
       
     }
     
     //Generate an event_name property for within eventObject to run the virtual cntainer instance    
     eventObject.event_name = requestQueryParameters[data.eventQueryParam] ? requestQueryParameters[data.eventQueryParam] : 'no_event';
     
    //Set aditional properties within eventObject from the incoming http request headers
    eventObject.page_referrer = getRequestHeader('referer');
    eventObject['x-params-country'] = getRequestHeader('X-Appengine-Country');
    eventObject['x-params-city'] = getRequestHeader('X-Appengine-City');
    //Uncoment the following line of code and configure to include any additional properties to eventObject from the desired request headers. Must include one line per requesHeader
    //eventObject[propertyName] = getRequestHeader('Header name');
     
    //Set aditional properties within eventObject from the incoming http request selected cookies. These cookies must be set at the same domain as the server tagging server
     if(data.cookieCheckbox){
      
      let cookies = data.cookieName.split(',');
      
      for(let i = 0; i < cookies.length; i++){
        
        eventObject['x-params-'+ cookies[i]+ '-cookie-value'] = getCookieValues(cookies[i]).toString();
      
      }
            
    }
     
    //If request request anonimization checkbox not checked, include user ip and user agent as properties of eventObject
    if(!data.anonymizeCheckbox){
    
      eventObject['x-params-user-Ip'] = getRequestHeader('X-Appengine-User-Ip');
      eventObject['x-params-user-agent'] = getRequestHeader('User-Agent');
      
    }
     
    //Generate a new object (containerEventParams) from eventObject (excluding the  eventObject[data.eventQueryParam] property that was used to generate the eventObject[event_name] property. This way we avoid object property duplication.  
    let containerEventParams = {};
    
    for(const property in eventObject ){
    
      if(property !== data.eventQueryParam){
        
        containerEventParams[property] = eventObject[property];
      
      }
    
    } 
     
    //Run container 
    runContainer(containerEventParams, () => returnResponse());    
     
   }
   
   //Code logi to be executed if POST request does not include a request body
   else if(!requestBody){
     
     //Generate an object from the request url's query parameters
     let eventObject = requestQueryParameters;
     
    //Generate an event_name property for within eventObject to run the virtual cntainer instance 
    eventObject.event_name = requestQueryParameters[data.eventQueryParam] ? requestQueryParameters[data.eventQueryParam] : 'no_event';
     
    //Set aditional properties within eventObject from the incoming http request headers 
    eventObject.page_referrer = getRequestHeader('referer');
    eventObject['x-params-country'] = getRequestHeader('X-Appengine-Country');
    eventObject['x-params-city'] = getRequestHeader('X-Appengine-City');
     //Uncoment the following line of code and configure to include any additional properties to eventObject from the desired request headers. Must include one line per requesHeader
    //eventObject[propertyName] = getRequestHeader('Header name');
  
  //Set aditional properties within eventObject from the incoming http request selected cookies. These cookies must be set at the same domain as the server tagging server   
  if(data.cookieCheckbox){
      
      let cookies = data.cookieName.split(',');
      
      for(let i = 0; i < cookies.length; i++){
        
        eventObject['x-params-'+ cookies[i]+ '-cookie-value'] = getCookieValues(cookies[i]).toString();
      
      }
            
    }
    
     //If request request anonimization checkbox not checked, include user ip and user agent as properties of eventObject
    if(!data.anonymizeCheckbox){
    
      eventObject['x-params-user-Ip'] = getRequestHeader('X-Appengine-User-Ip');
      eventObject['x-params-user-agent'] = getRequestHeader('User-Agent');
      
    }
     
    //Generate a new object (containerEventParams) from eventObject (excluding the  eventObject[data.eventQueryParam] property that was used to generate the eventObject[event_name] property. This way we avoid object property duplication. 
    let containerEventParams = {};
    
    for(const property in eventObject ){
    
      if(property !== data.eventQueryParam){
        
        containerEventParams[property] = eventObject[property];
      
      }
    
    }  
     
    //Run container 
    runContainer(containerEventParams, () => returnResponse());    
   
   }
   
 } 
   

}


___SERVER_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "read_request",
        "versionId": "1"
      },
      "param": [
        {
          "key": "requestAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        },
        {
          "key": "headerAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        },
        {
          "key": "queryParameterAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "return_response",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "run_container",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_response",
        "versionId": "1"
      },
      "param": [
        {
          "key": "writeResponseAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        },
        {
          "key": "writeHeaderAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "debug"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "get_cookies",
        "versionId": "1"
      },
      "param": [
        {
          "key": "cookieAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios: []


___NOTES___

Created on 28/12/2021 14:21:53


