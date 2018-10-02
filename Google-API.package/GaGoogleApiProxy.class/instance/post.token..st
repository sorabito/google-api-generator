actions-http
post: apiUrl token: apiToken
	| url req |
	url := ( ZnUrl fromString: apiUrl )
			queryAt: 'access_token' put: apiToken;
			yourself.		
	req := ZnRequest post: url.
	^req