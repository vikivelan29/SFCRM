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
					for (let i = 0; i < element.fieldsLeft.length; i++) {
						for (let key in element.fieldsLeft[i]) {
							if (payload[element.fieldsLeft[i][key]] || (element.fieldsLeft[i][key] + '').indexOf('.') != -1) {
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
							}
						}
					}

					for (let i = 0; i < element.fieldsRight.length; i++) {
						for (let key in element.fieldsRight[i]) {
							if (payload[element.fieldsRight[i][key]] || (element.fieldsRight[i][key] + '').indexOf('.') != -1) {

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
							}
						}
					}
					for (let i = 0; i < element.lTables.length; i++) {
						for (let key in element.lTables[i]) {
							if ((element.lTables[i][key] + '').indexOf('.') != -1) {
								// Check if payload contains .
								let value;
								if (element.lTables[i][key].includes('.')) {
									value = payload;

									let path = element.lTables[i][key].split('.');
									if (path.length > 0) {
										for (let i = 0; i < path.length; i++) {
											value = value[path[i]];
										}
									}
								} else {
									value = payload[element.lTables[i][key]];
								}

								// replace value from payload
								element.lTables[i][key] = value;
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
			console.log('error:' + error);
		});
}