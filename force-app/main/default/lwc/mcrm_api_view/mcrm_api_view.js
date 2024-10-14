import { LightningElement,api,track } from 'lwc';
import fetchAPIResponse from '@salesforce/apex/MCRM_APIController.invokeAPIwithParams';

export default class Wellness_api_view extends LightningElement {
    @api recordId;
	@api intAPIName;
    @api isShowDate = false;

    showSpinner = false;
	showBaseViewScreen = false;
	payloadInfo;
    responseMessage;
	responseArray = [];
    startDate;
    endDate;
    errorMessageSearch;
    displayErrorSearch = false;
	isError = false;
	errorMessage = "";
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
        this.isError = false;
		this.errorMessage = "";
        // invoke API
		const params = {
			startDate: this.startDate,
			endDate: this.endDate
		};
		fetchAPIResponse({ recId: this.recordId, intName:this.intAPIName , params : params})
		.then((result) => {
			let payLoad = JSON.parse(result.payload);

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
			if (this.payloadInfo) {
				this.showBaseViewScreen = true;
			} else {
				let res = JSON.parse(result?.payload);
				if(res?.error?.description) {
					this.showError(res.error.description);
				} else {
					this.showError("There seems to be an error");
				}
			}

			setTimeout(() => {             
				this.template.querySelector('c-mcrm_base_view_screen').callFunction();
			}, 200);
		})
		.catch((error) => {
			this.showSpinner = false;
			this.showError("There seems to be an error");
		});
    }

    handleSearchClick() {
		const allValid = [
            ...this.template.querySelectorAll('.inpFieldCheckValidity'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        if (allValid) {
			this.invokeAPI();
        }

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
			} else {
				this.displayErrorSearch = false;
			}
		} else {
			this.displayErrorSearch = false; // Hide error if one of the dates is missing
		}
	}

    showError(message) {
		this.isError = true;
		this.errorMessage = message;
    }

	handleRefresh(){
		this.invokeAPI();
	}
}