authentication
authenticationCredentialsFile
	authenticationCredentialsFile ifNil: [ | dir fn |
		dir := self authenticationCredentialsBaseDirectory.
		fn := ( GaGoogleApiTools replaceInvalidPathChars: self apiName ), '.', self id, '.auth.json'.
		fn := dir asFileReference / 'google_api_data' / fn.
		authenticationCredentialsFile := fn fullName ].
	
	^ authenticationCredentialsFile
