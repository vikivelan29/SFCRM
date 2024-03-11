import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { invokeCore } from 'c/abcl_base_view';

import errorMessage from '@salesforce/label/c.ASF_ErrorMessage';

export default class ABFL_DynamicScreen extends LightningElement {

	label = {
		errorMessage
	};

	title;
	screenjson;
	show = false;
	tblcolumns;
	tableData;
	isRenderDatatable = false;
	firstSection = "";

	@track _api_id;
	@api assetRecordId;
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

	async callFunction() {
		console.log('***callFunction-in');

		let res = await invokeCore(this._api_id, this.assetRecordId);
		console.log('***callFunction-success: ' + JSON.stringify(res));

		if (res.statusCode == 200) {
			this.title = res.title;
			this.screenjson = res.screen;
			this.show = true;
			this.firstSection = res?.screen[0]?.label;

			this.mergeLeftAndRightFieldSection(res);
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

			this.tblcolumns = res.screen[0].lTables[0].label;
			console.log('line 59: ' + JSON.stringify(res));
			this.tableData = res.screen[0].lTables[0].value;
			this.isRenderDatatable = this.tableData?.length > 0 ? true : false;
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
}