registration
registrationCredentialsFile
	registrationCredentialsFile ifNil: [ | dir fn |
		dir := self authenticationCredentialsBaseDirectory.
		fn := ( GaGoogleApiTools replaceInvalidPathChars: self apiName ), '.', self id, '.config.json'.
		fn := dir asFileReference / 'google_api_data' / fn.
		registrationCredentialsFile := fn fullName ].
	
	^ registrationCredentialsFile
