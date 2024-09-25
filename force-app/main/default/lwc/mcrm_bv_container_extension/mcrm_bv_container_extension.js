import { LightningElement, wire, api, track } from 'lwc';
import getTableMeta from '@salesforce/apex/MCRM_APIController.fetchTableMetadata';
import fetchAPIResponse from '@salesforce/apex/MCRM_APIController.invokeAPIwithParams';
import { subscribe, MessageContext } from 'lightning/messageService';
import ViewEvent from '@salesforce/messageChannel/mcrmviewevents__c';
import GymLocationNotAvailable from '@salesforce/label/c.MCRM_GymNameLocation';

export default class Mcrm_bv_container_extension extends LightningElement {

	label = {
		GymLocationNotAvailable
	};

	// Configs
	@api recordId;
	@api dynTableExAPI;
	pcvalue;
	options;
	
	// Internals
	showBaseView=false;
	showPartner=false;
	columns;
	@track tableData;
    isLoading = false;
	
	get hasNoData(){
		if(this.tableData.length>0){
			return 'slds-hide'
		}else{
			return '';
		}
	}
	get hasData(){
		if(this.tableData.length>0){
			return '';
		}else{
			return 'slds-hide'
		}
	}

	get disableButton(){
		return !(this.pcvalue);
	}

	@wire(MessageContext)
	messageContext;

	@wire (getTableMeta, {configName:'$dynTableExAPI'})
	tableMeta({ error, data }) {
        if (data) {
			console.log('***tableMeta>ext:'+this.dynTableExAPI);
			console.log('***tableMeta>ext:'+JSON.stringify(data));
            this.columns = [
				...data.map(col => ({
					label: col.MasterLabel,
					fieldName: col.Api_Name__c,
					type: col.Data_Type__c,
					cellAttributes: { alignment: 'left' }
				}))
			];
        } else if (error) {
			console.log('***error:'+JSON.stringify(error));
			console.log('***error:'+JSON.stringify(error.body.message));
            this.showToast('Error','Error fetching data.','Error');
        }
    }
	
	connectedCallback() {
		this.subscribeToMessageChannel();
	}

	subscribeToMessageChannel() {
		this.subscription = subscribe(
			this.messageContext,
			ViewEvent,
			(message) => this.handleMessage(message)
		);
	}

	handleMessage(message) {
		console.log('***message:'+JSON.stringify(message.name));	
		console.log('***message:'+JSON.stringify(message));	
		console.log('***dynTableExAPI:'+this.dynTableExAPI);	
		this.isLoading=true;
		if(this.dynTableExAPI =='MCRM_ActiveDays' && message.name=='MCRM_ActiveDayURL'){
			this.getActiveDays(message.payLoad);
		}else if(this.dynTableExAPI =='MCRM_GymNameLocation' && message.name=='MCRM_Gym_Voucher'){
			this.getGymNameLocation(message.payLoad);
		}
		
		this.showBaseView=true;
		this.isLoading=false;
	}

	getActiveDays(message){
		console.log('****getActiveDays>>>'+JSON.stringify(message));
		let responseArray = [];
		message.responseMap.resultsList.scores.forEach(score => {
			score.activities.forEach(activity => {
				responseArray.push(
					{
						'activeDate': score.activeDate,
						'isScored': score.isScored=='true'?'Yes':'No',
						'name': activity.name,
						'pc': activity.value,
						'score': activity.score,
						'eventDate': activity.eventDate,
						'sourceName': activity.sourceName,
					}
				)
			});
		});
		console.log('***responseArray:'+JSON.stringify(responseArray));	
		this.tableData = responseArray;
	}

	getGymNameLocation(message){
		// reset vars
		this.pcvalue='';
		this.tableData=[];
		this.keyField='partnerCode';

		console.log('****getGymNameLocation>>>'+JSON.stringify(message));
		this.showPartner=true;
		let partnerList = message
							.filter(ele=>{
								return ele.partnerCd;
							})
							.map(ele=>{
								return { label: ele.partnerCd, value: ele.partnerCd }
							});
		this.options=partnerList;
		console.log('****getGymNameLocation>>>'+JSON.stringify(this.options));
	}

	handleChange(event) {
        this.pcvalue = event.detail.value;
    }

	invokeAPI(parameters){
		console.log('***invokeAPI>'+JSON.stringify(parameters));
		fetchAPIResponse({ recId: this.recordId, intName:this.dynTableExAPI , params : parameters})
			.then((result) => {
				let payLoad = JSON.parse(result.payload);
				console.log('***result:child:'+JSON.stringify(payLoad));
				
				// Check validity of response
				if (result?.statusCode == 200 && payLoad) {
					let responseArray = [];
					console.log('***result:child1:'+JSON.stringify(payLoad));
					console.log('***result:child2:'+JSON.stringify(payLoad.responseMap));
					console.log('***result:child3:'+JSON.stringify(payLoad.responseMap.resultsList));
					
					responseArray.push(payLoad.responseMap.resultsList);
					this.template.querySelector("c-abc_base_tableview").refreshTable(responseArray);
					this.tableData = JSON.parse(JSON.stringify(responseArray));

					console.log('***tableData:rsn:'+this.dynTableExAPI+'>>'+JSON.stringify(responseArray));
				}else {
					console.error('***No tableData available.');
					let res = JSON.parse(result?.payload);
					if(res?.error?.description) {
						this.showToast("Error", res.error.description, 'error');
					} else {
						this.showToast("Error", "There seems to be an error child", 'error');
					}
				}
			})
			.catch((error) => {
				console.log('****Container:'+JSON.stringify(error));
				// console.log('***error:'+JSON.stringify(error.body.message));
   		 	});
	}

	handleClick(event){
		console.log('***handleClick>');
		// invoke api
		const parameters = {
			param1: this.pcvalue,
		};
		this.invokeAPI(parameters);
	}
}