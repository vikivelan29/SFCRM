import { api, LightningElement } from 'lwc';
import fetchDigitalErrors from '@salesforce/apex/ABAMC_DisplayDigitalErrorsController.fetchDigitalErrors';

import { reduceErrors } from 'c/asf_ldsUtils';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import TIME_ZONE  from '@salesforce/i18n/timeZone';
import MyModal from 'c/asf_simpleModal';


const columns = [
    { label: 'Updated Date', fieldName: 'updatedDatetime', type: 'date', initialWidth: 200,
        typeAttributes:{
            year: "2-digit",
            month: "short",
            day: "2-digit",
            hour: "2-digit",
            minute: "2-digit",
            timeZone: TIME_ZONE
        }
    },
    { label: 'Type', fieldName: 'eventType',initialWidth: 100 },
    { label: 'Message', fieldName: 'messageText',initialWidth: 550},
    { label: 'View', fieldName: 'id', type: 'button-icon',initialWidth: 80,
        typeAttributes: {
            label: { fieldName: 'View' },
            name: 'id',
            iconName: 'action:preview'
        },
    }
];

export default class Abamc_displayDigitalErrors extends LightningElement {
    data = [];
    columns = columns;
    defaultSortDirection = 'desc';
    sortDirection = 'desc';
    sortedBy;
    @api recordId;
    loading = true;
    displayTable = true;
    userMessage;


    connectedCallback(){
        console.log('connectedCallback');
        this.fetchData();
        this.loading = false;
    }

    async fetchData(){
        console.log('connectedCallback fetchData', this.recordId);
        if(this.recordId){
            let wrap = await fetchDigitalErrors({input:this.recordId}).catch((error)=>{
                console.error(error);
                this.showError('error', 'Oops! Something went wrong', error);
            });
            if(wrap.isSuccess){
                //handle success
                let response = JSON.parse(wrap.responseBody);
                //response = []; //to mock error scenario
                if(response.length == 0){
                    this.displayTable = false;
                    this.userMessage = 'No data found';
                }
                this.data = [];
                this.data = response.map((item)=>{
                    return {
                        'id':item._id,
                        'updatedDatetime':item._metadata.lastUpdated,
                        'eventType':item.eventType,
                        'messageText':item.messageText
                    };
                });
                this.sortedBy = 'updatedDatetime'
            }else{
                //handle API errors
                console.error(wrap.errorMessage);
                this.showError('error', 'Oops! Something went wrong', wrap.errorMessage);
            }
        }
    }
    viewRecord(event){
        console.log(event.detail.action.name);
        console.log(event.detail.row.id);
        let selectedId = event.detail.row.id;
        let selectedRow = this.data.find(item=>{
            return item.id == selectedId;
        });
        console.log('selectedRow',selectedRow);
        let currentDateVal = new Date(selectedRow.updatedDatetime);
        let formattingOptions = {
            year: 'numeric',
            month: '2-digit',
            day: '2-digit',
            timeZone: 'IST',
            hour12:true,
  			hour:'2-digit',
  			minute:'2-digit'
        };
        let currentDateLocale = currentDateVal.toLocaleString('en-IN', formattingOptions);
        MyModal.open({
            content:selectedRow.messageText,
            header:currentDateLocale + ' / '+ selectedRow.eventType,
            label:currentDateLocale + ' / '+ selectedRow.eventType,
            footeraction:'Okay'
        }).then((result) => {
              console.log(result);
          }).catch(error=>{
            console.error(error);
          });
    }

    refreshData(){
        this.loading = true;
        this.fetchData();
        this.loading = false;
    }

    // Used to sort the 'Age' column
    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                  return primer(x[field]);
              }
            : function (x) {
                  return x[field];
              };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    onHandleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.data];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.data = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    //utility method
    showError(variant, title, error) {
        let errMsg = reduceErrors(error);
        const event = new ShowToastEvent({
            variant: variant,
            title: title,
            message: Array.isArray(errMsg) ? errMsg[0] : errMsg
        });
        this.dispatchEvent(event);
    }
    showSuccessMessage(variant, title, message) {
        const event = new ShowToastEvent({
            variant: variant,
            title: title,
            message: message
        });
        this.dispatchEvent(event);
    }
}