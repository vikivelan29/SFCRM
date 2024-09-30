import { LightningElement,api,wire } from 'lwc';
import getTableMeta from '@salesforce/apex/MCRM_APIController.fetchTableMetadata';
import fetchAPIResponse from '@salesforce/apex/MCRM_APIController.invokeAPIwithDate';
import { publish, MessageContext } from 'lightning/messageService';
import ViewEvent from '@salesforce/messageChannel/mcrmviewevents__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { customerAPIs } from 'c/mcrm_base_view_account';
import { contractAPIs } from 'c/mcrm_base_view_asset';

export default class Wellness_api_view extends LightningElement {
	// Configs
	@api dynTableAPI;
	@api secName;
    @api fireApiOnLoad;
    @api isShowDate;
    @api isCollapsed;
    @api showRefresh;
    @api passPayload;
	
	// Context var
	@api recordId;
	@api objectApiName;
	@wire(MessageContext)
  	messageContext;

	// Internals
	startDate;
	endDate;
    isLoading = false;
	tableData;
	columns;
	showBaseView = false;
	activeSections=[];
    connectedCallback(){
        if(this.isShowDate==false && this.fireApiOnLoad==true && !this.isCollapsed){
            this.invokeAPI();
        }
		if(!this.isCollapsed){
			this.activeSections.push('activeSection')
		}
    }

	@wire (getTableMeta, {configName:'$dynTableAPI'})
	tableMeta({ error, data }) {
        if (data) {
            this.columns = [
				...data.map(col => ({
					label: col.MasterLabel,
					fieldName: col.Api_Name__c,
					type: col.Data_Type__c,
					cellAttributes: { alignment: 'left' }
				}))
			];
        } else if (error) {
            this.showToast('Error','Error fetching data.','Error');
        }
    }

    invokeAPI(){
        this.isLoading = true;
        // invoke API
		const dateParams = {
			startDate: this.startDate,
			endDate: this.endDate
		};
		// RSN: HC
		fetchAPIResponse({ recId: this.recordId, intName:this.dynTableAPI , dates : dateParams})
		.then((result) => {
			let payLoad = JSON.parse(result.payload);
			
			// Check validity of response
			if (result?.statusCode == 200 && payLoad) {
				// invoke helper
				if(this.objectApiName=='Account'){
					this.tableData = customerAPIs(this.dynTableAPI, payLoad);
				}else{
					this.tableData = contractAPIs(this.dynTableAPI, payLoad);
				}
			}
			this.isLoading = false;
			if (this.tableData) {
				this.showBaseView = true;
				if(this.passPayload){
					// publish event
					publish(this.messageContext, ViewEvent, {payLoad,'name':this.dynTableAPI});
				}
			} else {
				let res = JSON.parse(result?.payload);
				if(res?.error?.description) {
					this.showToast("Error", res.error.description, 'error');
				} else {
					this.showToast("Error", "There seems to be an error", 'error');
				}
			}
		})
		.catch((error) => {
			// console.log('***error:'+JSON.stringify(error.body.message));
			this.isLoading = false;
			this.showToast("Error", "Admin: There seems to be an error", 'error');
		});
    }

    handleSearchClick(){
		this.invokeAPI();
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

	handleStartDateChange(event){		
		this.startDate = event.target.value;
	}

	handleEndDateChange(event){		
		this.endDate = event.target.value;
	}

	handleToggleSection(event) {
		if(this.isShowDate==false && this.fireApiOnLoad==true){
			this.invokeAPI();
		}
    }

	handleMenuSelect(event) {
		this.invokeAPI();
    }
}