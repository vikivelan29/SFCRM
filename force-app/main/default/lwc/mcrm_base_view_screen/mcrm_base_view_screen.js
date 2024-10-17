import { LightningElement, track, api } from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { invokeCore } from 'c/abcl_base_view';

import errorMessage from '@salesforce/label/c.ASF_ErrorMessage';

export default class mcrm_base_view_screen extends LightningElement {

	label = {
		errorMessage
	};

	@api showRefresh;
	@api showPreview;

	title;
	isShowModal = false;
	isLoading = false;
	screenjson;
	show = false;
	tblcolumns;
	firstSection = "";
	showPagination = false;
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
		this.showRefresh=true;
		this.showPreview=true;
	}

	coreResult;
	@api
	async callFunction() {
		
		this.coreResult = await invokeCore(this._api_id, this.payloadInfo);
		await this.generateScreen();
	}

	@api
	async generateScreen() {
		try {
			let res = this.coreResult;
			if(res){
				this.isLoading = true;

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
						let pageSize = false;						
						// Iterate over lTables to parse and transform the labels
						lTables.forEach(table => {
							// Transform the labels
							pageSize = table.value.length>10 ? true : false;
							
							table.label = this.transformLabels(table.label);
						});
						
						screen.showpagination = pageSize;
						
					});
					
				}

				this.isLoading = false;
			}
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

	handleMenuSelect(){
		this.dispatchEvent(new CustomEvent("refresh"));

	}

	get divBlock(){
        return this.columns?.length==1?'width:25%':'';
    }
    get divClass(){
        return this.changeView?'slds-modal__container':'';
    }
    get secClass(){
        return this.changeView?'slds-modal slds-fade-in-open slds-modal_medium slds-modal_large':'';
    }
    get headClass(){
        return this.changeView?'slds-modal__header':'slds-hide';
    }
    get bodyClass(){
        return this.changeView?'slds-modal__content slds-p-around_medium':'';
    }
    get backClass(){
        return this.changeView?'slds-backdrop slds-backdrop_open':'';
    }
    changeView=false;
    handleChangeView(){
        this.changeView=this.changeView==true?false:true;
		if(this.changeView==true){
			this.showPreview=false;
		}
        console.log('***changeView:'+this.changeView);
    }

    closeModal(){
    	this.handleChangeView();
		this.showPreview=true;
    }
	
	get refreshClass(){
		return (this.showPreview==true)?"slds-float_right mcrmButton mcrmRefresh":"slds-float_right mcrmButton";
	}
}