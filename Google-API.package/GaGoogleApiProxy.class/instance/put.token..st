actions-http
put: apiUrl token: apiToken
	| url req |
	url := ( ZnUrl fromString: apiUrl )
			queryAt: 'access_token' put: apiToken;
			yourself.		
	req := ZnRequest put: url.
	^req