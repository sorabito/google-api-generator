initialize-release
initialize
	super initialize.
	methodActions := { 
		#GET -> #get:token:.
		#PUT -> #put:token:.
		#POST -> #post:token:.
	 } asDictionary 
	