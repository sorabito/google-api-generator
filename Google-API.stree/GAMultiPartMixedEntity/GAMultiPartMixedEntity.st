
ZnMultiPartFormDataEntity subclass: #GAMultiPartMixedEntity
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Google-API'!

!GAMultiPartMixedEntity commentStamp: 'RichardPrinz 3/4/2015 17:20' prior: 0!
Extension to ZnMultiPartFormDataEntity to use a mimetype of multipart/mixed


!

!GAMultiPartMixedEntity class methodsFor: 'as yet unclassified'!
designatedMimeType
	^ ZnMimeType main: 'multipart' sub: 'mixed'! !
