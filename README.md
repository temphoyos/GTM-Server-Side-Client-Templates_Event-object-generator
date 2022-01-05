# GTM-Server-Side-Client-Templates_Event-object-generator
This Google Tag Manager server side client template can digest any http GET or POST request incoming to your tagging server. It will generate an event object from the url's query params, request headers, cookies and request body and run a virtual container instance with your current server container configuration. 

# How to import this server-side client template into your GTM server container
1. Download the .tpl file you will find in this repository
2. Browse to your GTM container and clic on 'Templates', at the bottom of the left hand side menu
3. Clic on the 'New' button you will find at the top right corner of the 'Client templates' section, at the top of the screen
4. You will now be seeing the client template creation window, clic on the three dots you will find at the top right corner of the screen. 
5. Now clic on 'Import' abd select the .tpl file you downloaded from this repository
6. It is important that you clic on the 'Permissions' tab (top menu) and configure any necessary permissions. This client template has all the necessary API permisions set to the lowest level by default.
7. When done configuring your permissions, clic on 'Save', on the upper right corner of the screen

# How to use this server-side custom template
In order to start using this server-side client template in your GTM server container follow these steps: 

1. Browse to your GTM server container and clic on 'Clients', on the left hand side menu
2. Clic on 'New', and once you've accesed the client configuration screen clic on the pencil icon
3. Now select the 'Event object generator' from the custom tempalte list. 

Now you are ready to configure the client's settings. These are the setting you need to configure:

1. 'Origins allowed to send http requests to this end point'. The client will only accept incoming http requests from the domains you list here. If you include several of them, separate them with commas. Do not include the https:// protocol before each domain name. 
2. 'http request path to be claimed by the client'. The client will be waiting to claim the incoming http requests that have the path you input here.
3. 'Query param containing the event name or type'. In order for the client template to successfully run a virtual instance of your GTM server container, you need to generate an object containing an event_name property. Use this field to input the incoming http request query parameter containing the event name (eg: page_view, purchase...) The client template will generate an object with an event_name property containing this query param's value
4. 'Include cookie value in event object?'. If you wish to include certain cookies as part of the event object's properties, tic this checkbox. You will then be prompted to input the name of the cookie you wish to include. If including several, separat their names with commas. IMPORTANT: Cookies must be set to the same domain of the tagging server.
5. 'Anonymize event object'. If you mark this checkbox, the user IP and User Agent will not be included in the event object. 
