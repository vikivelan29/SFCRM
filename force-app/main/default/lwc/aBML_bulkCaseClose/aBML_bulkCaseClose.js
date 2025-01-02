import { LightningElement, track, wire ,api } from 'lwc';
import GetFrameworkCases from '@salesforce/apex/Abml_CaseCloseBulkHandler.GetFrameworkCases';
import UpdateCase from '@salesforce/apex/Abml_CaseCloseBulkHandler.UpdateCase';
import getSearchRecords from '@salesforce/apex/Abml_CaseCloseBulkHandler.getSearchRecords';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';






export default class ABML_bulkCaseClose extends LightningElement {

    
@track listViewOptions = []; 
    @track caseRecords = [];   
    isModalOpen = false; // Controls modal visibility
     textValue = '';
     
      @track selectedCaseIds = []; 
       isTextAreaVisible = false; // Controls visibility of the text area
    textValue = '';  
    
    columns = [
        { 
            label: 'Case Number', 
            fieldName: 'ConName', //caseLink
            sortable:true,
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'CaseNumber' },
                target: '_blank'
            } 
        },
        { label: 'Subject', fieldName: 'Subject', sortable:true },
        { label: 'Description', fieldName: 'Description', sortable:true },
        { label: 'Date/Time Opened', fieldName: 'CreatedDate', sortable:true },
        { label: 'Email Address', fieldName: 'SuppliedEmail', sortable:true }, 
    ];



 data;
    //columns = this.columns;
    defaultSortDirection = 'asc';
    isSectionOpen = false;
    sortDirection = 'asc';
    sortedBy;
    searchString;


    @wire(GetFrameworkCases)
    wiredListViews({ data, error }) {
        if (data) {
            this.caseRecords = data;

            console.log('the data is',this.caseRecords);

             let tempConList = []; 
            
            data.forEach((record) => {
                let tempConRec = Object.assign({}, record);  
                tempConRec.ConName = '/' + tempConRec.Id;
                tempConList.push(tempConRec);
                
            });
            
            this.caseRecords = tempConList;


        } else if (error) {
            console.error('Error fetching List Views', error);
        }
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;

        

         console.log('the CASE are', this.caseRecords);

        console.log('the ids are',event.detail.selectedRows);

        this.selectedCaseIds = selectedRows.map(row => row.Id);

        console.log('the ids are',this.selectedCaseIds);
        //this.caseIds = this.selectedCaseIds;
    }


    OpenModalUserSection(){

    this.isSectionOpen = true;
        

    }


    handleContinue() {
        this.isSectionOpen = false; // Close the modal
        
        this.UpdateCaseClosure()

        // Add any further logic here
    }



    closePopUpModal() {
        this.isSectionOpen = false;
    }


    UpdateCaseClosure(){
 
            console.log('Selected cases are ::: '+this.selectedCaseIds);
            const caseIdsToPass = Array.isArray(this.selectedCaseIds) ? this.selectedCaseIds : [this.selectedCaseIds];
            UpdateCase({ caseId : caseIdsToPass,
                         Descript : this.textValue
            
            
                 })
               .then(result => {
                   this.error = undefined;
                   this.showToast('Success','Cases Closed succesfully','success');
                   
                   //return refreshApex(this.caseRecords);
                   window.location.reload();
               })
               .catch(error => {
                   
                   this.error = 'Failed to Update cases: ' + JSON.stringify(error);
                   //this.showToast('Error', 'Failed to fetch users: ' + error.body.message, 'error');
               });            
               
          }

           showToast(title, message, variant) {
            const toastEvent = new ShowToastEvent({
                title:title,
                message: message,
                variant: variant,
                mode: 'pester' // Can be 'dismissable', 'pester', or 'sticky'
            });
            this.dispatchEvent(toastEvent);
        }


    handleSearchChange(event) {
        this.searchString = event.target.value; // Update the case search string
        this.searchUsers(); // Fetch cases based on the new search string
        //this.selectedCaseIds = this.caseIds;
    }

    // Search Users in the Selected Queue
    searchUsers() {
        

        // Call Apex to get cases with the search string
        getSearchRecords({ searchText: this.searchString })
            .then(result => {
                this.caseRecords = result;

                let tempConList = []; 
                result.forEach((record) => {
                    let tempConRec = Object.assign({}, record);  
                    tempConRec.ConName = '/' + tempConRec.Id;
                    tempConList.push(tempConRec);
                    
                });
                
                this.caseRecords = tempConList;
                
                 // Update the users data
            })
            .catch(error => {
                this.users = []; // Clear the table on error
                this.showToast('Error', 'Failed to fetch users: ' + error.body.message, 'error');
            });
    }



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
        const cloneData = [...this.caseRecords];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.caseRecords = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }


    openModal() {
        this.isModalOpen = true;
    }

    // Close the modal
    closeModal() {
        this.isModalOpen = false;
    }

    // Handle text area input
    handleTextChange(event) {
        this.textValue = event.target.value;
    }

    // Save the text (you can extend this to save data to Salesforce)
    saveText() {
        console.log('Text Saved:', this.textValue);
        this.closeModal();
    }



}