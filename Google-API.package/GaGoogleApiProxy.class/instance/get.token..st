actions-http
get: apiUrl token: apiToken
	| url req |
	url := ( ZnUrl fromString: apiUrl )
			queryAt: 'access_token' put: apiToken;
			yourself.		
	req := ZnRequest get: url.
	^req