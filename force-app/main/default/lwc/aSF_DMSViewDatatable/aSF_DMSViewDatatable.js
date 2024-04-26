import { LightningElement, wire, api, track } from 'lwc';
import getColumns from '@salesforce/apex/Asf_DmsViewDataTableController.getColumns';
import executeQuery from '@salesforce/apex/Asf_DmsViewDataTableController.executeQuery';
import DMS_URL from '@salesforce/label/c.DMS_URL';
import getUserBDid from '@salesforce/apex/Asf_DmsViewDataTableController.getUserBDid';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class ASF_DMSViewDatatable extends LightningElement {
    data = [];
    columns = [];
    baseUrl;
    @api recordId;
    @wire(getColumns)
    wiredColumns({error, data}) {
        if (data) {
            this.columns = [  {
                label: 'DMS File Name',
                fieldName: 'accLink',
                type: 'url',
                typeAttributes: { label: { fieldName: 'Name' }, target: '_self' }
            },
                ...data.map(col => ({
                label: col.MasterLabel,
                fieldName: col.Api_Name__c,
                type: col.Data_Type__c,
                cellAttributes: { alignment: 'left' }
            })), 
            //{ label: 'Link', type: 'button', typeAttributes: { label: 'View Link', name: 'viewLink', variant: 'base' } },
            //{ label: 'Sync Status', type: 'button', typeAttributes: { label: 'Sync Manually', name: 'manualSync', variant: 'base' }}
          
            ];
            //if (this.recordStatus === 'Success') {
                // Add 'Link' and 'Sync Status' buttons
              
         //   }
            
            // Assign columns to this.columns
        } else if (error) {
            console.error('Error fetching columns: ', error);
        }
    }
    @wire(executeQuery, { caseId: '$recordId' })
    wiredData({ error, data }) {
        if (data) {
            data = JSON.parse(JSON.stringify(data));
            data.forEach(res => {
                res.accLink = '/' + res.Id;
                if(res.DMS_External_ID__c== null){
                    res.showButtons = true;
                }
                res.showButtonsSynch = res.Status__c === 'Success'; // Show buttons if Status__c is 'Success'
                res.actionText = res.Status__c === 'Success' ? 'Synched already' : 'Synch Manually';

            });
            this.data = data;
            this.columns = [
                ...this.columns,
                {
                    label: 'Actions',
                    type: 'button',
                    typeAttributes: {
                        label: 'View Link',
                        name: 'viewLink',
                        variant: 'base',
                        disabled: { fieldName: 'showButtons' } // Disable buttons conditionally based on 'showButtons' attribute
                    }
                },
                {
                    label: 'Manual Synching',
                    type: 'button',
                    typeAttributes: {
                        label: { fieldName: 'actionText' }, // Use the actionText field for the button label
                        name: 'manualSync',
                        variant: 'base',
                        disabled: { fieldName: 'showButtonsSynch' } // Disable buttons conditionally based on 'showButtonsSynch' attribute
                    }
                }
            ];
    
    
            this.error = undefined;
        } else if (error) {
            console.error('Error fetching records:', error);
            this.error = error;
            this.data = [];
        } 
    }
    handleRowAction(event) {
        const action = event.detail.action;
        const row = event.detail.row;
        console.log('Row Object:', JSON.stringify(row));
        if (action.name === 'viewLink') {
            if(row.DMS_External_ID__c == null || row.DMS_External_ID__c == undefined ){
                const event = new ShowToastEvent({
                    title: 'Error',
                    message: 'Document Id is null',
                    variant: 'Error', 
                });
                this.dispatchEvent(event);
            }
            else{
                const userBDidH = 'UserBDid'; 
                getUserBDid({userBDid: userBDidH })
                    .then(result => {
                        console.log('UserBDid:', result);
                        this.baseUrl = DMS_URL;
                        const userdbid = result;
                        // Constructing full dynamic URL
                        const documentId = row.DMS_External_ID__c; 
                        const dynamicUrl = `${this.baseUrl}&Userdbid=${userdbid}&DocumentId=${documentId}`;
                        console.log('dynamicUrl:', dynamicUrl);
                        if(userdbid != null || userdbid != undefined){
                            window.open(dynamicUrl, '_blank');
                        }
                    })
                    .catch(error => {
                        console.error('Error:', error);
                    });
            }
        }
       else if (action.name === 'manualSync') {
        console.log('manualSync ');
        // logic for manual synching to be added here
        }
        
    }
    navigateToApexHoursPage(dynamicUrla) {
        console.log('dynamicnavigatesUrl:', dynamicUrla);
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: dynamicUrla
            }
        });
    }
}