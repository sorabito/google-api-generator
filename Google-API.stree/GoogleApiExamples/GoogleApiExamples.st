
Object subclass: #GoogleApiExamples
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Google-API'!

!GoogleApiExamples commentStamp: 'RichardPrinz 3/4/2015 17:06' prior: 0!
Provides some class side samples for using Google APIs!

!GoogleApiExamples class methodsFor: 'as yet unclassified'!
addTestFileToGoogleDrive
	| fileApi fileName localFilePath remoteFile now result | 
	
	" add a simple text file to Google Drive "
	" see https://developers.google.com/drive/v2/reference/files/insert "
	
	" create and authenticate API "
	fileApi := GoogleDriveApiFiles new.
	fileApi authenticate. 

	" create a local file "
	now := DateAndTime now.
	fileName := ( '{1}{2}{3}-{4}{5}{6}' format: {
		now year . now month asTwoCharacterString . now dayOfMonth asTwoCharacterString .
		now hours asTwoCharacterString . now minutes asTwoCharacterString . now seconds asTwoCharacterString } ), '.txt'.

	localFilePath := (FileSystem workingDirectory) / 'google_api_data_tests' / fileName.
	localFilePath asFileReference writeStreamDo: [ :stream | 
		stream nextPutAll: 'I am a test file created by Pharo smalltalk named (', fileName, ')' ].

	" define remote file parameters "
	remoteFile := Dictionary new.
	remoteFile 
		add: 	'title'			-> fileName;
		add: 	'description'	-> 'A file created with Pharo SmallTalk';
		add: 	'mimeType'		-> 'text/plain';
		add: 	'CONTENT'		-> ( ( FileStream readOnlyFileNamed: localFilePath ) contents ).

	" send request "
	[ result := fileApi insert: remoteFile ] on: Error do: [ :ex |
		ex inspect.
		self halt ]. 

	" after transfer delete local file "
	localFilePath asFileReference delete.
	
	^ result
	! !

!GoogleApiExamples class methodsFor: 'as yet unclassified'!
listGoogleDriveFiles
	| files fileApi result items | 
	
	" list files in Google Drive in the Transcript see "
	" https://developers.google.com/drive/v2/reference/files/list "
	
	fileApi := GoogleDriveApiFiles new.
	fileApi authenticate. 
	
	" send request "
	[ result := fileApi list ] on: Error do: [ :ex |
		ex inspect.
		self halt ]. 
	
	" display listing in transcript window "
	files := result at: 2.	
	items := files at: 'items' ifAbsent: [ Array new ].
	items do: [ :item || fileName labels isDeleted |
		fileName := item at: 'title' ifAbsent: [ 'unknown' ].
		labels := item at: 'labels' ifAbsent: [ Dictionary new ].
		isDeleted := labels at: 'trashed' ifAbsent: [ false ].
		
		Transcript show: fileName, '  ', 
			[ isDeleted 
				ifTrue: [ '(deleted)' ] 
				ifFalse: [ '' ] ] value; cr ].
	
	^ result
	! !

!GoogleApiExamples class methodsFor: 'as yet unclassified'!
reCompile

self class compile: (( self class methodDictionary at: #listGoogleDriveFiles ) ast source).
self class compile: (( self class methodDictionary at: #addTestFileToGoogleDrive ) ast source).! !
