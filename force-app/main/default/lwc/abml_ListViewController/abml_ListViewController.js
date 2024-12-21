import { LightningElement, track, wire } from 'lwc';
import getCaseListViews from '@salesforce/apex/ABML_QueueController.getCaseListViews';
import getCaseRecords from '@salesforce/apex/ABML_QueueController.getCaseRecords';
import getSearchRecords from '@salesforce/apex/ABML_QueueController.getSearchRecords';

export default class Abml_ListViewController extends LightningElement {

@track listViewOptions = []; 
    @track caseRecords = [];   
    @track selectedListViewId = '';  
    @track selectedCaseIds = [];  
    
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
        { label: 'Owner Name', fieldName: 'OwnerText__c', sortable:true }, // OwnerId
    ];

    data;
    //columns = this.columns;
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy;
    searchString;
    @track showChildComponent=false;
    @track caseIds;

    // Wire to get List Views for Case
    @wire(getCaseListViews)
    wiredListViews({ data, error }) {
        if (data) {
            this.listViewOptions = data.map(view => ({
                label: view.Name,
                value: view.Id
            }));
        } else if (error) {
            console.error('Error fetching List Views', error);
        }
    }

    // Handle List View selection change
    handleListViewChange(event) {
        this.selectedListViewId = event.detail.value;
        this.fetchCaseRecords(); // Fetch records for the selected List View
    }

    // Fetch Case records based on selected List View
    fetchCaseRecords() {
        if (this.selectedListViewId) {
            getCaseRecords({ listViewId: this.selectedListViewId })
                .then(data => {
                    this.caseRecords = data;
                    this.data = data;

                    /*data.forEach(res => {
                        res.caseLink = '/' + res.Id;
                    });*/
                    //caseLink: '/lightning/r/Case/${caseRecord.Id}/view';
                    let tempConList = []; 
            
            data.forEach((record) => {
                let tempConRec = Object.assign({}, record);  
                tempConRec.ConName = '/' + tempConRec.Id;
                tempConList.push(tempConRec);
                
            });
            
            this.caseRecords = tempConList;

                })
                .catch(error => {
                    console.error('Error fetching Case records', error);
                });
        }
    }

    // Handle row selection and capture selected Case IDs
    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedCaseIds = selectedRows.map(row => row.Id);
        //this.caseIds = this.selectedCaseIds;
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

    updateRecordStatus(){
        this.showChildComponent = true;
    }
    hideModalBox(){
        this.showChildComponent = false;
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
        const cloneData = [...this.caseRecords];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.caseRecords = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

        /*sortDirection = 'asc';
        sortedBy = 'Subject';

        // Handle sorting
    handleSort(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.data];
        
        cloneData.sort(this.sortData(sortedBy, sortDirection));

        // Set the sorted data and sort direction
        this.data = cloneData;
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;
    }

    // Sort function
    sortData(fieldName, direction) {
        const multiplier = direction === 'asc' ? 1 : -1;
        return function(a, b) {
            if (a[fieldName] > b[fieldName]) {
                return 1 * multiplier;
            } else if (a[fieldName] < b[fieldName]) {
                return -1 * multiplier;
            } else {
                return 0;
            }
        };
    }*/
}