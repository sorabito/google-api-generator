
Object subclass: #GoogleApiProxy
	instanceVariableNames: 'id session registrationCredentialsFile authenticationCredentialsFile methodAction'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Google-API'!

!GoogleApiProxy commentStamp: 'RichardPrinz 3/4/2015 17:06' prior: 0!
The base class of all created Google API proxy classes !

!GoogleApiProxy methodsFor: 'api'!
apiName
	self subclassResponsibility! !

!GoogleApiProxy methodsFor: 'utilities'!
argumentsFor: aMethodContext
	| temps arguments |
	
	arguments := Dictionary new.
	temps := aMethodContext tempNames.
	1 to: temps size do: [ :i | 
		arguments at: ( temps at: i ) put: ( aMethodContext tempAt: i ) ].
		
	^ arguments
	! !

!GoogleApiProxy methodsFor: 'authentication'!
authenticate
	| authJson regUrl |
	
	regUrl := self register.
			
	" try to read authentication json file, if missing start authentication process "
	[ authJson := self authenticationCredentials ] 
		on: Error do: [ | code |			
			"
				display dialog asking the user to browse to auth url for requesting an authentication code.
				requests auth code from user. 
				If no code was entered or dialog canceld do nothing
				if code was entered create tokens and save in authentication json file for
				later use
			"
			code := GoogleApiAuthDialog open: regUrl asString.
			code ifNil: [ ^false ].	
			authJson := self register: code ].

	session accessToken: ( authJson at: 'access_token' ifAbsent: [ nil ] ).
	session refreshToken: ( authJson at: 'refresh_token' ifAbsent: [ nil ] ).
	"session tokenType: ( authJson at: 'token_type' ifAbsent: [ nil ] )."

	^ true
	! !

!GoogleApiProxy methodsFor: 'registration'!
authenticate: parameterDictionary
	| fn |

	fn := self authenticationCredentialsFile asFileReference.
	fn writeStreamDo: [ :stream | 
		stream nextPutAll: ( 
			NeoJSONWriter toString: parameterDictionary ) ].

	^ parameterDictionary
	! !

!GoogleApiProxy methodsFor: 'authentication'!
authenticateRefresh
	| isAuthOK parameterDictionary |

	isAuthOK := self authenticate.
	isAuthOK ifFalse: [ ^false ].
	
	session handleTokenRefresh.
	
	parameterDictionary := Dictionary new.
	parameterDictionary at: 'access_token' put: session accessToken.
	parameterDictionary at: 'refresh_token' put: session refreshToken.
	parameterDictionary at: 'token_type' put: session tokenType.
	
	self authenticate: parameterDictionary.
	
	^ true
	! !

!GoogleApiProxy methodsFor: 'authentication'!
authenticationCredentials
	| fn authJson |
	
	fn := self authenticationCredentialsFile asFileReference.
	fn exists ifFalse: [ 
		self error: 'API not registered. Authentication file (', fn fullName, ') missing' ].	
	
	authJson := ( fn readStream ) contents.	
	authJson := NeoJSONReader fromString: authJson.	
		
	^ authJson! !

!GoogleApiProxy methodsFor: 'authentication'!
authenticationCredentialsFile
	authenticationCredentialsFile ifNil: [ | dir fn |
		dir := FileSystem workingDirectory.
		fn := ( GoogleApiTools replaceInvalidPathChars: self apiName ), '.', self id, '.auth.json'.
		fn := dir / 'google_api_data' / fn.
		authenticationCredentialsFile := fn fullName ].
	
	^ authenticationCredentialsFile
! !

!GoogleApiProxy methodsFor: 'authentication'!
authenticationCredentialsFile: aFileName
	authenticationCredentialsFile := aFileName
! !

!GoogleApiProxy methodsFor: 'api'!
basePath
	self subclassResponsibility ! !

!GoogleApiProxy methodsFor: 'accessing'!
id
	id ifNil: [ id := 'default' ].
	
	^ id! !

!GoogleApiProxy methodsFor: 'accessing'!
id: aString
	id := GoogleApiTools replaceInvalidPathChars: aString.
! !

!GoogleApiProxy methodsFor: 'as yet unclassified'!
initialize
	super initialize.
	
	methodAction := Dictionary new.
	
	methodAction at: #GET put: [ :apiUrl :token || url req |
		url := ( ZnUrl fromString: apiUrl )
			queryAt: 'access_token' put: token;
			yourself.		
		req := ( ZnRequest get: url ).
		req ].
	
	methodAction at: #PUT put: [ :apiUrl :token || url req |
		url := ( ZnUrl fromString: apiUrl )
			queryAt: 'access_token' put: token;
			yourself.		
		req := ( ZnRequest put: url ).
		req ].
	
	methodAction at: #POST put: [ :apiUrl :token || url req |
		url := ( ZnUrl fromString: apiUrl )
			queryAt: 'access_token' put: token;
			yourself.		
		req := ( ZnRequest post: url ).
		req ].

! !

!GoogleApiProxy methodsFor: 'api'!
makeRequestTo: aUrl usingMethod: httpMethod with: aParamDictionary
	| a  req res client returnCode auth content  |
	
	session ifNil: [
		self error: 'Authenticate API first with #authenticate' ].

	a := methodAction at: httpMethod ifAbsent: [
		self error: 'Unsupported http method (', httpMethod, ')' ].

	client := ZnClient new.
	
	" create request "
	req := a value: aUrl value: ( session accessToken ).
	
	client
		request: req;
		method: ( req method ).
		
	( aParamDictionary isNotNil and: [ aParamDictionary size > 0 ] ) ifTrue: [ | json part contentMime |
		req entity: GAMultiPartMixedEntity new.
		client request url queryAt: 'uploadType' add: 'multipart'.
		
		content := aParamDictionary at: 'CONTENT' ifAbsent: [ ].
		aParamDictionary removeKey: 'CONTENT' ifAbsent: [ ].
		content := ( Base64MimeConverter mimeEncode: content readStream ) contents.		
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
				req := a value: aUrl value: ( session accessToken ).
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
	

! !

!GoogleApiProxy class methodsFor: 'as yet unclassified'!
newWithId: aString
	^ self new
		id: aString;
		yourself! !

!GoogleApiProxy methodsFor: 'registration'!
register
	| url |
	
	" try to read configuration json file to construct authentication url "
	
	session := ZnGoogleOAuth2Session google: self registrationCredentials.
	session beOfflineAccessType;
		forceApprovalPrompt;
		scopes: ( self scopes ).

	url := session authenticationUrl.
	
	^ url
	! !

!GoogleApiProxy methodsFor: 'registration'!
register: aRegistrationCode
	|  parameterDictionary |
	
	" Accepts the code from registration url request "

	session ifNil: [ 
		self error: 'Start registration with #register' ].
	
	( parameterDictionary := Dictionary new ) 
		add: 'code' -> aRegistrationCode.
	
	session handleAuthenticationCallback: parameterDictionary.
	
	"
		If we come here without errors registration was OK
		save session accessToken & session refreshToken & session tokenType 
		in authenticationCredentials json file
	"
	
	parameterDictionary := Dictionary new.
	parameterDictionary at: 'access_token' put: session accessToken.
	parameterDictionary at: 'refresh_token' put: session refreshToken.
	parameterDictionary at: 'token_type' put: session tokenType.

	self authenticate: parameterDictionary.
	
	^ parameterDictionary
	! !

!GoogleApiProxy methodsFor: 'registration'!
registrationCredentials
	|  fn cfgJson client_id client_secret redirect_url |

	" reads a json file with registration credentials. use Google api console to create one "

	fn := self registrationCredentialsFile asFileReference.
	fn exists ifFalse: [ self error: 'API registration credentials file (', fn fullName, ') missing.' ].	
	
	cfgJson := ( fn readStream ) contents.	
	cfgJson := NeoJSONReader fromString: cfgJson.
	cfgJson := cfgJson at: 'installed' ifAbsent: [ {} ].
	
	client_id := cfgJson at: 'client_id' ifAbsent: [ '' ].
	client_secret := cfgJson at: 'client_secret' ifAbsent: [ '' ].
	redirect_url := cfgJson at: 'redirect_uris' ifAbsent: [ #() ].
	redirect_url := redirect_url at: 1 ifAbsent: [ '' ].
	
	^ ZnOAuth2ConsumerData 
			key: client_id
			secret: client_secret
			redirectUrl: redirect_url
! !

!GoogleApiProxy methodsFor: 'registration'!
registrationCredentialsFile
	registrationCredentialsFile ifNil: [ | dir fn |
		dir := FileSystem workingDirectory.
		fn := ( GoogleApiTools replaceInvalidPathChars: self apiName ), '.', self id, '.config.json'.
		fn := dir / 'google_api_data' / fn.
		registrationCredentialsFile := fn fullName ].
	
	^ registrationCredentialsFile
! !

!GoogleApiProxy methodsFor: 'registration'!
registrationCredentialsFile: aFileName
	registrationCredentialsFile := aFileName
! !

!GoogleApiProxy methodsFor: 'utilities'!
replacePlaceholdersIn: aTemplateString with: aDictionary 
	| template params w reg |
	
	" 
	GoogleApiTools replacePlaceholders: 'I am a {param}' 
		with: { 'param' -> 'test' } asDictionary 
	"
	
	template := aTemplateString.
	template ifNil: [ template := '' ]
			ifNotNil: [ template := template asString ].
	
	params := aDictionary.
	params ifNil: [ params := Dictionary new ].
	
	reg := '({([a-zA-Z0-9_]+)})' asRegex.
	w := aTemplateString 
			copyWithRegex: '{[a-zA-Z0-9_]+}' 
			matchesTranslatedUsing: [ :placeholder || key value |
				reg matchesPrefix: placeholder.
				key := reg subexpression: 3.
				value := aDictionary at: key ifAbsent: [ reg subexpression: 2 ].
				value asString
			].
	^ w! !

!GoogleApiProxy methodsFor: 'api'!
scopes
	self subclassResponsibility! !

!GoogleApiProxy methodsFor: 'accessing'!
session
	^ session! !
