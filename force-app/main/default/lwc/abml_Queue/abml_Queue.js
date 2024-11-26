import { LightningElement,api,track } from 'lwc';
import getQueues from "@salesforce/apex/ABML_QueueController.getQueueNames";
import getUsersByQueue from "@salesforce/apex/ABML_QueueController.getUsersByQueue";
import getUsersInQueue from "@salesforce/apex/ABML_QueueController.getUsersInQueue";
import UpdateCaseOwner from "@salesforce/apex/ABML_QueueController.updateCaseOwner";
import getCaseDetails from "@salesforce/apex/ABML_QueueController.getCaseDetails";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import dt_colors from '@salesforce/resourceUrl/ABML_Datatable_Css';
import {loadStyle} from 'lightning/platformResourceLoader';
import checkBusinessHours from "@salesforce/apex/ABML_QueueController.checkBusinessHours";
import checkAssignedPermissionSet from "@salesforce/apex/ABML_QueueController.checkAssignedPermissionSet";
import LightningAlert from 'lightning/alert';







export default class ABML_Queue extends LightningElement {

 isListening = false;

    pickListOrdered;
    selectedrecordid;
    searchResults;
    selectedSearchResult;
    selectedQueue;
    users;
    userName;
    isUserExist = false;
    error;
     @api recordId;
     @api listRecordId;
     cases;
     @track hideCases = false;
     @track checkLength;
     @track businessHours = true;
     @track checkProfile = true;
     @track booleanValue;

     columns = [
        { label: 'Name', fieldName: 'Name' },
        { label: 'Email', fieldName: 'Email' },
        
       
       
    ];

    caseColumns = [
        { label: 'Case Number', fieldName: 'CaseNumber' },
        { label: 'Subject', fieldName: 'Subject' },
        
       
    ];

    get selectedValue() {
        return this.selectedSearchResult?.label ?? null;
    }

    connectedCallback() {

        checkBusinessHours()
            .then(result => {
                this.businessHours = result;
                console.log('im here checkBusinessHours ');
                console.log('boolean value:',result);

                if(this.businessHours==false){
                    //alert('The case cannot be configured after business hours, please assign the case tomorrow');
                    LightningAlert.open({
                        message: 'The case cannot be configured after business hours, please assign the case tomorrow',
                        theme: 'warning', // a red theme intended for error states
                        label: 'Warning!', // this is the header text
                    });
                }else if(this.businessHours==true){

                    //Profile Validation starts--
             checkAssignedPermissionSet()
            .then(result => {
                this.checkProfile = result;
                console.log('im here checkProfile ');
                console.log('--checkProfile value:',this.checkProfile);
                if(this.checkProfile==false){ //this.businessHours==true &&
                    this.businessHours = false;
                    //alert('You dont have access to this component!');
                    LightningAlert.open({
                        message: 'This is specific to ABML team assignment. You do not have access to this functionality',
                        theme: 'warning', 
                        label: 'Warning!', 
                    });
                }else{
                    this.businessHours = true;
                }
                
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
            });
            //Profile Validation ends--

                }
                
                this.error = undefined;
            })
            .catch(error => {
                this.error = error;
            });
            
            

        getQueues().then((result) => {
            this.pickListOrdered = result.sort((a, b) =>
                a.label.localeCompare(b.label)
            );
        });

        getCaseDetails({ caseIdList: this.recordId })
            .then(result => {
                this.cases = result;
                if(result.length >= 1){
                    this.hideCases = true;
                    this.checkLength = result.length;
                }else{
                    this.hideCases = false;
                    this.checkLength = result.length;
                }
                
                console.log('im here 3+++ ')
                console.log('the length of array',result.length);
                //this.isUserExist = result.length > 0 ? true : result.length === 0 ? false : false;

                
                //console.log('the user returned',this.users);
                this.error = undefined;
            })
            .catch(error => {
                this.cases = undefined;
                this.error = 'Failed to load cases: ' + JSON.stringify(error);
            });
    }

    renderedCallback() {
        if (this.isListening) return;

        window.addEventListener("click", (event) => {
            this.hideDropdown(event);
        });
        this.isListening = true;

        if(this.isCssLoaded) return
        this.isCssLoaded = true
        loadStyle(this, dt_colors).then(()=>{
            console.log("Loaded Successfully")
        }).catch(error=>{ 
            console.error("Error in loading the colors")
        })
    }


    /**
     * This function compares the name of the component (`cmpName`) with the name of the clicked element (`clickedElementSrcName`).
     * If the clicked element is outside the component, the dropdown (search results) is hidden by calling `clearSearchResults()`.
     *
     * - `cmpName` is the tag name of the host element of this component (e.g., 'C-SEARCHABLE-COMBOBOX').
     * - `clickedElementSrcName` is the tag name of the element that was clicked on the page.
     * - `isClickedOutside` is a boolean that is true if the clicked element is outside the component.
     */
    hideDropdown(event) {
        const cmpName = this.template.host.tagName;
        const clickedElementSrcName = event.target.tagName;
        const isClickedOutside = cmpName !== clickedElementSrcName;
        if (this.searchResults && isClickedOutside) {
            this.clearSearchResults();
        }
    }

    search(event) {
        const input = event.detail.value.toLowerCase();
        const result = this.pickListOrdered.filter((pickListOption) =>
            pickListOption.label.toLowerCase().includes(input)
        );
        this.searchResults = result;
    }

    selectSearchResult(event) {
        const selectedValue = event.currentTarget.dataset.value;
        console.log('im here ',selectedValue);
        this.selectedQueue = event.currentTarget.dataset.value;
        console.log('the value is',this.selectedQueue);
        this.fetchUsers();
        this.selectedSearchResult = this.pickListOrdered.find(
            (pickListOption) => pickListOption.value === selectedValue
        );
        this.clearSearchResults();
    }

    clearSearchResults() {
        this.searchResults = null;
    }

    showPickListOptions() {
        if (!this.searchResults) {
            this.searchResults = this.pickListOrdered;
        }
    }

  fetchUsers() {
        getUsersByQueue({ queueId: this.selectedQueue })
            .then(result => {
                this.users = result;
                console.log('im here 3+++ ')
                console.log('the length of array',result.length);
                this.isUserExist = result.length > 0 ? true : result.length === 0 ? false : false;

                
                console.log('the user returned',this.users);
                this.error = undefined;
            })
            .catch(error => {
                this.users = undefined;
                this.error = 'Failed to load users: ' + JSON.stringify(error);
            });
    }

     handleRowSelection(event) {
        console.log('in handlerowselection');
        var selectedRows = event.detail.selectedRows;
        this.selectedrecordid = selectedRows[0].Id;
        console.log('Selected rows are '+JSON.stringify(selectedRows[0]));
        console.log('Selected rows user id is '+JSON.stringify(selectedRows[0].Id));    
    }


     handleUserSearchChange(event) {
        this.userName = event.target.value; // Update the user search string
        this.searchUsers(); // Fetch users based on the new search string
    }

    // Search Users in the Selected Queue
    searchUsers() {
        

        // Call Apex to get users in the selected queue with the search string
        getUsersInQueue({ queueId: this.selectedQueue, userName: this.userName })
            .then(result => {
                this.users = result;
                
                
                 // Update the users data
            })
            .catch(error => {
                this.users = []; // Clear the table on error
                this.showToast('Error', 'Failed to fetch users: ' + error.body.message, 'error');
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


     updateRecordStatus() {

        if(this.recordId.length==0){
            LightningAlert.open({
                message: 'Please select a case to assign',
                theme: 'warning', 
                label: 'Warning!', 
            });
        }else if(this.selectedrecordid==undefined){
            LightningAlert.open({
                message: 'Please select user from the list',
                theme: 'warning', 
                label: 'Warning!', 
            });
        } else{

        
        UpdateCaseOwner({ caseIdList: this.recordId, ownerId: this.selectedrecordid })
        .then(() => {
            this.showToast('Success','Records updated succesfully','success');
            this.successMessage = 'Record updated successfully!';
            this.errorMessage = '';
            console.log('im here ');
            //window.location.reload();
            console.log('this.checkLength',this.checkLength);
            console.log('this.recordId.length',this.recordId.length);
            if(this.recordId.length >= 1){
                //window.history.back();
                window.location.reload();
                console.log('im here 2');
            }/*else{
                window.location.reload();
            }*/
            
               
        })
        .catch((error) => {
            
            this.showToast('Error updating record',error.body.message,'error');
            this.errorMessage = 'Error updating record: ' + error.body.message;
            console.log('the id of case is',this.recordId);
            console.log('the error message is ',this.errorMessage);
            
                console.log('the id of owner is',this.selectedrecordid);
            this.successMessage = '';
        });
    }
    }


}
