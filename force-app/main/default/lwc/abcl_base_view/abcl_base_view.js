import getDynamicScreen from '@salesforce/apex/ABCL_BaseViewController.getDynamicScreen';
export function invokeCore(apiId, payloadInfo) {
	return getDynamicScreen({ apiName: apiId})
		.then((result) => {
			let statusCode;
			let screenjson;
			let title;

			title = result.title;
			statusCode = payloadInfo.statusCode;
			screenjson = JSON.parse(JSON.stringify(result.secWrap));
			
			console.log('***result.secWrap:' + JSON.stringify(result.secWrap));
			console.log('***payload:' + JSON.stringify(payloadInfo));

			let payload =  JSON.parse(payloadInfo.payload);
			if (screenjson && payload) {
				screenjson.forEach(element => {
					console.log('***element ==> '+JSON.stringify(element));
					for (let i = 0; i < element.fieldsLeft.length; i++) {
						for (let key in element.fieldsLeft[i]) {
							console.log('***payloadk ==> '+payload[element.fieldsLeft[i][key]]);
							console.log('key:'+key);
							if (key=='value' && (typeof payload[element.fieldsLeft[i][key]] !== 'undefined' || (element.fieldsLeft[i][key] + '').indexOf('.') != -1)) {
								// Check if payload contains .
								let value;
								if (element.fieldsLeft[i][key].includes('.')) {
									value = payload;
									
									// retrieve path
									let path = element.fieldsLeft[i][key].split('.');
									if (path.length > 0) {
										for (let i = 0; i < path.length; i++) {
											value = value[path[i]];;
										}
									}
								} else {
									value = payload[element.fieldsLeft[i][key]];
								}
								// replace value from payload
								element.fieldsLeft[i][key] = value;
								break;
							}
							// VIRENDRA - Added to set empty value when response JSON is not returning the Key.
							else if (key=='value' && (typeof payload[element.fieldsLeft[i][key]] === 'undefined' || 
							typeof payload[element.fieldsLeft[i][key]] === null)){
								element.fieldsLeft[i][key] = '';
							}
							/*else{
								element.fieldsLeft[i][key] = '';
								break;
							}*/
						}
					}

					for (let i = 0; i < element.fieldsRight.length; i++) {
						for (let key in element.fieldsRight[i]) {
							if (key=='value' && (typeof payload[element.fieldsRight[i][key]] !== 'undefined' || (element.fieldsRight[i][key] + '').indexOf('.') != -1)) {
								// Check if payload contains .
								let value;
								if (element.fieldsRight[i][key].includes('.')) {
									value = payload;

									let path = element.fieldsRight[i][key].split('.');
									if (path.length > 0) {
										for (let i = 0; i < path.length; i++) {
											value = value[path[i]];
										}
									}
								} else {
									value = payload[element.fieldsRight[i][key]];
								}
								// replace value from payload
								element.fieldsRight[i][key] = value;
								break;
							}
							// VIRENDRA - Added to set empty value when response JSON is not returning the Key.
							else if (key=='value' && (typeof payload[element.fieldsRight[i][key]] == 'undefined' || 
								typeof payload[element.fieldsRight[i][key]] == null)) {
									element.fieldsRight[i][key] = '';
									break;
							}
						}
					}
					for (let i = 0; i < element.lTables.length; i++) {
						for (let key in element.lTables[i]) {
							if(key == 'value'){
								console.log('inside value ...*****');
								if ((element.lTables[i][key])) {
									// Check if payload contains .
									let value;
									if (element.lTables[i][key].includes('.')) {
										console.log('inside includes ** ');
										value = payload;

										let path = element.lTables[i][key].split('.');
										if (path.length > 0) {
											for (let i = 0; i < path.length; i++) {
												value = value[path[i]];
											}
										}
									} else {
										console.log('inside else of includes')
										value = payload[element.lTables[i][key]];
									}

									// replace value from payload
									element.lTables[i][key] = value;
								}
							}
							else{

							}
						}
					}
				});

				console.log('***final:' + JSON.stringify(screenjson));
				return {
					'statusCode': statusCode,
					'title': title,
					'screen': screenjson
				};
			} else {
				return {
					'statusCode': statusCode,
					'title': title
				};
			}
		})
		.catch((error) => {
			console.log('error:' + JSON.stringify(error));
		});
}