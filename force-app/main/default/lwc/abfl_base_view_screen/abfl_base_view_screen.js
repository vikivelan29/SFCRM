import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { invokeCore } from 'c/abcl_base_view';

import errorMessage from '@salesforce/label/c.ASF_ErrorMessage';

export default class Abfl_base_view_screen extends LightningElement {

	label = {
		errorMessage
	};

	title;
	isShowModal = false;
	isLoading = false;
	screenjson;
	show = false;
	tblcolumns;
	firstSection = "";

	@track _api_id;
	@api payloadInfo;
	@api
	get api_id() {
		return this._api_id;
	}
	set api_id(value) {
		this._api_id = value;
	}

	connectedCallback() {
		this.callFunction();
	}
	@api
	async callFunction() {
		try {
			console.log('***callFunction-in'+JSON.stringify(this.payloadInfo));

			this.isLoading = true;

			let res = await invokeCore(this._api_id, this.payloadInfo);
			console.log('***callFunction-success: ' + JSON.stringify(res));

			if (this.payloadInfo?.statusCode == 200 && res?.screen) {
				this.title = res.title;
				this.screenjson = res.screen;
				this.show = true;
				this.firstSection = res?.screen[0]?.label;
				this.mergeLeftAndRightFieldSection(res);
				this.isShowModal = true;
			} else {
				this.dispatchEvent(new CustomEvent('closemodal'));
				const evt = new ShowToastEvent({
					title: 'Error',
					message: this.label.errorMessage,
					variant: 'error',
				});
				this.dispatchEvent(evt);
			}

			if (this.show) {
				res.screen.forEach(screen => {
					// Extracting lTables from the current screen
					let lTables = screen.lTables;

					// Iterate over lTables to parse and transform the labels
					lTables.forEach(table => {
						// Transform the labels
						table.label = this.transformLabels(table.label);
						console.log('line 55: ' + JSON.stringify(table.label));
					});
				});
			}

			this.isLoading = false;
		} catch (error) {
			this.isLoading = false;
			console.log("An error occurred: " + JSON.stringify(error));
		}
	}

	transformLabels(labelString) {
		let labelsArray = labelString.split(',');
		let transformedArray = [];

		labelsArray.forEach(labelItem => {
			let [fieldName, label] = labelItem.split(':');
			transformedArray.push({
				label: label,
				fieldName: fieldName
			});
		});

		return transformedArray;
	}

	mergeLeftAndRightFieldSection(data) {
		// Iterate through each screen in the 'screens' array
		data.screen.forEach(screen => {
			// Check if 'fieldsLeft' and 'fieldsRight' exist
			if (screen.fieldsLeft && screen.fieldsRight) {
				// Initialize an empty array to store merged fields
				screen.fields = [];
	
				// Determine the length of the merged fields
				const maxLength = Math.max(screen.fieldsLeft.length, screen.fieldsRight.length);
	
				// Merge 'fieldsLeft' and 'fieldsRight' into a new 'fields' array
				for (let i = 0; i < maxLength; i++) {
					if (screen.fieldsLeft[i]) {
						screen.fields.push(screen.fieldsLeft[i]);
					}
					if (screen.fieldsRight[i]) {
						screen.fields.push(screen.fieldsRight[i]);
					}
				}
	
				// Remove 'fieldsLeft' and 'fieldsRight'
				delete screen.fieldsLeft;
				delete screen.fieldsRight;
			}
		});
	
		// Stringify the modified object back to JSON
		const transformedJson = JSON.stringify(data, null, 2);
	
		return transformedJson;
	}

	closeModal(){
    	this.isShowModal = false;
    }
}