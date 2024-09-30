import { LightningElement,api,track } from 'lwc';
import fetchAPIResponse from '@salesforce/apex/MCRM_APIController.invokeAPIwithDate';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Wellness_api_view extends LightningElement {
    @api recordId;
	@api intAPIName;
    @api isShowDate = false;

    showSpinner = false;
    showErrorMessage = false;
	showBaseViewScreen = false;
	payloadInfo;
    responseMessage;
	responseArray = [];
    startDate;
    endDate;
    errorMessageSearch;
    displayErrorSearch = false;

    get isDirectInvoke(){
        return !this.isShowDate;
    }

    connectedCallback(){
        if(this.isDirectInvoke){
            this.invokeAPI();
        }
    }

    invokeAPI(){
        this.showSpinner = true;
        this.showErrorMessage = false;
        // invoke API
		const dateParams = {
			startDate: this.startDate,
			endDate: this.endDate
		};
		console.log('dateParams-->'+dateParams);
		fetchAPIResponse({ recId: this.recordId, intName:this.intAPIName , dates : dateParams})
		.then((result) => {
			let payLoad = JSON.parse(result.payload);
			console.log('***result:'+JSON.stringify(JSON.parse(JSON.stringify(result))));

			// Check validity of response
			if (result?.statusCode == 200 && payLoad) {
				this.payloadInfo = result;
				if(this.isShowDate){
                    let pl = {rows:[]};
				    pl.rows.push(payLoad.responseMap.resultsList);
				    this.payloadInfo.payload=JSON.stringify(pl);
                }
			}
			this.showSpinner = false;
			console.log('***payloadInfo:'+JSON.stringify(this.payloadInfo));
			if (this.payloadInfo) {
				this.showBaseViewScreen = true;
			} else {
				let res = JSON.parse(result?.payload);
				if(res?.error?.description) {
					this.showToast("Error", res.error.description, 'error');
				} else {
					this.showToast("Error", "There seems to be an error", 'error');
				}
			}

			setTimeout(() => {             
				this.template.querySelector('c-abfl_base_view_screen').callFunction();
			}, 200);
		})
		.catch((error) => {
			console.log(JSON.stringify(error));
			this.showSpinner = false;
			this.showToast("Error", "There seems to be an error", 'error');
		});
    }

    handleSearchClick() {
        if(this.displayErrorSearch){
            this.showToast("Error", this.errorMessageSearch, 'error');
            return;
        }

		this.invokeAPI();
    }

    handleStartDateChange(event) {
        this.startDate = event.target.value;
        this.validateDates();
    }

    handleEndDateChange(event) {
        this.endDate = event.target.value;
        this.validateDates();
    }

	validateDates() {
		if (this.startDate && this.endDate) {
			const start = new Date(this.startDate);
			const end = new Date(this.endDate);
	
			if (end < start) {
				this.displayErrorSearch = true;
				this.errorMessageSearch= 'End Date cannot be earlier than Start Date.';
			} else {
				this.displayErrorSearch = false;
			}
		} else {
			this.displayErrorSearch = false; // Hide error if one of the dates is missing
		}
	}

    showToast(title, message, type) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: type,
            mode: 'dismissable'
        });
        this.dispatchEvent(event);
    }

	handleRefresh(){
		this.invokeAPI();
	}
}