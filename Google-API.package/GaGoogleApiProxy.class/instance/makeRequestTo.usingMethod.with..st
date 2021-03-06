api
makeRequestTo: aUrl usingMethod: httpMethod with: aParamDictionary
	| answerSelector  req res client returnCode auth content |
	
	session ifNil: [
		self error: 'Authenticate API first with #authenticate' ].

	answerSelector := self methodActions at: httpMethod ifAbsent: [ self error: 'Unsupported http method (', httpMethod, ')' ].

	client := ZnClient new.
	
	" create request "
	req := self perform: answerSelector with: aUrl with: session accessToken.
	
	client
		request: req;
		method: ( req method ).
		
	( aParamDictionary isNotNil and: [ aParamDictionary size > 0 ] ) ifTrue: [ | json part contentMime |
		req entity: GaMultiPartMixedEntity new.
		client request url queryAt: 'uploadType' add: 'multipart'.
		
		aParamDictionary at: 'CONTENT' ifPresent: [ :cont |
			aParamDictionary removeKey: 'CONTENT' ifAbsent: [ ].
			content := ( Base64MimeConverter mimeEncode: cont readStream ) contents.
		].		
		contentMime := aParamDictionary at: 'mimeType' ifAbsent: [ 'application/octet-stream' ].		
		json := NeoJSONWriter toString: aParamDictionary.
		
		json ifNotNil: [
			part := ZnMimePart new.
			part entity: ( ( ZnStringEntity 
				type: ( ZnMimeType main: 'application' sub: 'json' ) )
				string: json;
				yourself ).
			req entity addPart: ( part ).
			].
		
		content ifNotNil: [
			part := ZnMimePart new.
			part entity: ( ( ZnStringEntity 
				type: ( ZnMimeType fromString: contentMime ) )
				string: content;
				yourself ).
			part headers at: 'Content-Transfer-Encoding' put: 'base64'.
			req entity addPart: ( part ) ].
		
		"aParamDictionary keysAndValuesDo: [ :key :val |
			z addPart: (ZnMimePart fieldName: key value: val).
			]."
		].


"st := WriteStream on: ( String new ).
client request writeOn: st.
st inspect."

	
	res := client
		execute.
	returnCode := client response statusLine code.

	" if we get a 401 return and have a refresh token try a refreshAuthenticate and repeat request "
	( returnCode = 401 ) ifTrue: [
			session refreshToken ifNotNil: [
				auth := self authenticateRefresh.

				" recreate url with frefreshed tokens and repeat request "
				req := self perform: answerSelector with: aUrl with: session accessToken.
				res := client
					request: req;
					execute.
				returnCode := client response statusLine code ] ].
	
	" if request was not successfull throw erro with result in tag "
	( returnCode < 200 or: [ returnCode > 299 ] ) ifTrue: [
		Error new
			tag: res;
			signal: 'Request returns non OK status code (', returnCode asString, ')' ].

	content := res.
	( client response entity contentType matches: ZnMimeType applicationJson ) ifTrue: [
		content := NeoJSONReader fromString: res ].
		
	^ { client response. content. }
	

