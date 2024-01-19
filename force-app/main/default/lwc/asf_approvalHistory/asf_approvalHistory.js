import { LightningElement, api, track, wire } from "lwc";
import getApprovalHistory from "@salesforce/apex/ASF_ApprovalHistoryController.getApprovalHistory";
//import submitForApprovalApex from "@salesforce/apex/ASF_ApprovalHistoryController.submitForApproval";
//import reassignStep from "@salesforce/apex/ASF_ApprovalHistoryController.reassignStep";
import processStep from "@salesforce/apex/ASF_ApprovalHistoryController.processStep";
import searchUsers from "@salesforce/apex/ASF_ApprovalHistoryController.searchUsers";
import searchQueue from "@salesforce/apex/ASF_ApprovalHistoryController.searchQueues";
import {
  verifyIfNextApproverWasNeeded,
  hideModal,
  showModal,
  getCommentPropertyFromModal,
  showGetNextApproverModal,
  validateUserLookup,
  setSelectedUser,
  clearModalState,
  displayToast,
  extractErrorMessage,
  modalStates,
  displayToastErrorQuery
} from "./approvalHistoryUtil";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";

const ERROR = "error";
const SUCCESS = "success";

const columns = [
  {
    label: "Step Name",
    fieldName: "stepUrl",
    type: "url",
    typeAttributes: {
      label: {
        fieldName: "stepName"
      }
    }
  },
  {
    label: "Date",
    fieldName: "createdDate",
    type: "date",
    typeAttributes: {
      month: "numeric",
      day: "numeric",
      year: "numeric",
      hour: "numeric",
      minute: "numeric"
    }
  },
  {
    label: "Actual Approver",
    fieldName: "assignedToUrl",
    type: "url",
    typeAttributes: {
      label: {
        fieldName: "assignedTo"
      }
    }
  },
  { label: "Status", fieldName: "stepStatus" },
  {
    label: "Assigned To",
    fieldName: "actualapproverToUrl",
    type: "url",
    typeAttributes: {
      label: {
        fieldName: "actualapprover"
      }
    }
  },
  {
    label: "Delegated?",
    fieldName: "bDelegatedApprover",
    type: "boolean"
  }
];

export default class Asf_approvalHistory extends LightningElement {
    @api recordId;
    @api showComments; //Determines if the component will show the comments column
    @api allowSubmitForApproval; //determines if the component will allow Submit for Approval functionality
    @track approvalHistory; //approval history to display on page
    wiredApprovalHistory; //property used to refreshApex
  
    //modal properties
    currentModalState; //decides which type of modal to display depending on the action happening(approve, reject, recall, etc)
    modalComment; //temporarily stores the value of the comment input field in the modal
    selectedUser; //temporarily stores the selected user from the lookup component in the modal
    //end modal properties
  
    //lookup properties
    lookupErrors = []; //errors related to the lookup component
    isMultiEntry = false;
    initialSelection = [];
    //end lookup properties
  
    isUserBtnSelected = false;
    isQueueBtnSelected = false;
    strLookupPlaceHolder = '';
  
    elementUser;
    elementQueue;
  
    get columns() {
      let tempColumns = columns;
      if (this.showComments) {
        tempColumns.push({
          label: "Comments", fieldName: "comments"
        });
      }
  
      return tempColumns;
    }
  
    //url that will display all of the approval process history
    get viewAllUrl() {
      return "/lightning/r/" + this.recordId + "/related/ProcessSteps/view";
    }
    get showLookupAfterUserOrQueueSelection() {
      return (
        this.isUserBtnSelected || this.isQueueBtnSelected
      );
    }
  
  
  
    //decides if it will show the menu that may two buttons, the recall and the reassign 
    get showButtonMenu() {
      return (
        this.approvalHistory.isCurrentUserApprover ||
        this.approvalHistory.showRecall
      );
    }
  
    //decides if it will show the submit for approval button
    get showSubmitForApprovalButton() {
      return this.approvalHistory &&
        this.approvalHistory.showSubmitForApproval &&
        this.allowSubmitForApproval
        ? true
        : false;
    }
    get commentRequired() {
      return modalStates[this.currentModalState].commentRequired;
    }
  
    //will return a different modal title depending on the state 
    get modalTitle() {
      if (this.currentModalState && modalStates[this.currentModalState])
        return modalStates[this.currentModalState].title;
      return "";
    }
    // will return a different label for the submit button, depending on the current state.(Approve, Reject, Submit, etc)
    get modalsubmitLabel() {
      if (this.currentModalState && modalStates[this.currentModalState])
        return modalStates[this.currentModalState].submitLabel;
      return "";
    }
  
    // decides if the comment input field will show in the modal, based on the current state
    get showCommentModal() {
      return (
        this.currentModalState === modalStates.SUBMIT_APPROVAL.state ||
        this.currentModalState === modalStates.APPROVE.state ||
        this.currentModalState === modalStates.REJECT.state ||
        this.currentModalState === modalStates.RECALL.state
      );
    }
  
    // decides if the lookup component will show in the modal, based on the current state
    get showLookupModal() {
      return (
        this.currentModalState === modalStates.GET_NEXT_APPROVER_SUBMIT.state ||
        this.currentModalState === modalStates.REASSIGN.state ||
        this.currentModalState === modalStates.GET_NEXT_APPROVER_APPROVE.state
      );
    }
  
    // decides the label for the lookup component, based on the current state
    get lookupLabel() {
      return modalStates[this.currentModalState].lookupLabel;
    }
  
    get showDataTable() {
      return this.approvalHistory && this.approvalHistory.approvalSteps.length > 0
        ? true
        : false;
    }
  
    @wire(getApprovalHistory, { recordId: "$recordId" })
    wiredGetApprovalHist(value) {
      this.wiredApprovalHistory = value;
      if (value.data) {
        this.approvalHistory = value.data;
      } else if (value.error) {
        displayToastErrorQuery(this, ShowToastEvent);
      }
    }
  
    refreshApprovalHistory() {
      refreshApex(this.wiredApprovalHistory);
    }
  
    @api
    submitForApproval() {
      this.handleSubmitForApprovalClick();
    }
    //button click handlers
    //the handlers show the modal and change the currentModalState depending on the button clicked
  
    handleSubmitForApprovalClick() {
      showModal(this);
      this.currentModalState = modalStates.SUBMIT_APPROVAL.state;
    }
  
    handleUserClick(evt) {
      console.log('This is User Click...');
      this.isUserBtnSelected = true;
      this.isQueueBtnSelected = false;
      this.strLookupPlaceHolder = 'Search User...';
      this.selectedUser = '';
      this.elementUser.classList.add('buttonCancelActive');
      this.elementUser.classList.remove('cancel-btn');
      this.elementQueue.classList.remove('buttonQueueActive');
      this.elementQueue.classList.add('accept-btn');
  
    }
    handleQueueClick(evt) {
      console.log('This is Queue Click...');
      this.isUserBtnSelected = false;
      this.isQueueBtnSelected = true;
      this.strLookupPlaceHolder = 'Search Queue...';
      this.selectedUser = '';
      this.elementUser.classList.remove('buttonCancelActive');
      this.elementUser.classList.add('cancel-btn');
      this.elementQueue.classList.add('buttonQueueActive');
      this.elementQueue.classList.remove('accept-btn');
  
    }
  
    handleReassignClick() {
      showModal(this);
      this.isQueueBtnSelected = false;
      this.isUserBtnSelected = false;
      this.currentModalState = modalStates.REASSIGN.state;
    }
  
    handleRecallClick() {
      showModal(this);
      this.currentModalState = modalStates.RECALL.state;
    }
  
    handleApproveClick() {
      showModal(this);
      this.currentModalState = modalStates.APPROVE.state;
    }
  
    handleRejectClick() {
      showModal(this);
      this.currentModalState = modalStates.REJECT.state;
    }
    //end button click handlers
  
    //this function submits for approval, if a next approver is needed, 
    //it will show the next approver modal which will trigger the submition again.
    submitForApprovalApexCall() {
      hideModal(this);
      submitForApprovalApex({
        recordId: this.recordId,
        comments: this.modalComment,
        nextApproverId: this.selectedUser
      })
        .then(result => {
          let jsonResult = JSON.parse(result);
          if (jsonResult.success) {
            displayToast(this, ShowToastEvent, SUCCESS);
            this.refreshApprovalHistory();
          } else {
            displayToast(this, ShowToastEvent, ERROR);
          }
          clearModalState(this);
        })
        .catch(error => {
          if (verifyIfNextApproverWasNeeded(error.body.pageErrors)) {
            showGetNextApproverModal(this, modalStates.GET_NEXT_APPROVER_SUBMIT.state);
          } else {
            let errorMessage = extractErrorMessage(error.body.pageErrors);
            displayToast(this, ShowToastEvent, ERROR, errorMessage);
            clearModalState(this);
          }
        });
    }
  
    //function that takes care of reassigning the pending step to the selected user.
    reassignApexCall() {
      hideModal(this);
      reassignStep({ recordId: this.recordId, newActorId: this.selectedUser })
        .then(() => {
          displayToast(this, ShowToastEvent, SUCCESS);
          clearModalState(this);
          this.refreshApprovalHistory();
        })
        .catch(() => {
          displayToast(this, ShowToastEvent, ERROR);
          clearModalState(this);
        });
    }
  
    //function that takes care of approve, reject, and recall. If next approver is needed
    //it will show the next approver modal which will trigger the submition again.
    processStepApexCall(action) {
      hideModal(this);
      processStep({
        recordId: this.recordId,
        comments: this.modalComment,
        nextApproverId: this.selectedUser,
        action: action
      })
        .then(result => {
          let jsonResult = JSON.parse(result);
          if (jsonResult.success) {
            displayToast(this, ShowToastEvent, SUCCESS);
            this.refreshApprovalHistory();
          } else {
            displayToast(this, ShowToastEvent, ERROR);
          }
          clearModalState(this);
        })
        .catch(error => {
          if (verifyIfNextApproverWasNeeded(error.body.pageErrors)) {
            showGetNextApproverModal(this, modalStates.GET_NEXT_APPROVER_APPROVE.state);
          } else {
            let errorMessage = extractErrorMessage(error.body.pageErrors);
            displayToast(this, ShowToastEvent, ERROR, errorMessage);
            clearModalState(this);
          }
        });
    }
  
    handleModalCancel() {
      hideModal(this);
      clearModalState(this);
    }
  
    //function that handles the modal Submit button.
    //depending on the current state, it will call the appropriate imperative method
    handleModalSubmit() {
      switch (this.currentModalState) {
        /*case modalStates.SUBMIT_APPROVAL.state:
          this.modalComment = getCommentPropertyFromModal(this);
          this.submitForApprovalApexCall();
          break;
        case modalStates.GET_NEXT_APPROVER_SUBMIT.state:
          if (validateUserLookup(this)) {
            setSelectedUser(this);
            this.submitForApprovalApexCall();
          }
          break;
        case modalStates.REASSIGN.state:
          if (validateUserLookup(this)) {
            setSelectedUser(this);
            this.reassignApexCall();
          }
          break;*/
        case modalStates.APPROVE.state:
          this.modalComment = getCommentPropertyFromModal(this);
          this.processStepApexCall(modalStates.APPROVE.action);
          break;
        /*case modalStates.GET_NEXT_APPROVER_APPROVE.state:
          if (validateUserLookup(this)) {
            setSelectedUser(this);
            this.processStepApexCall(modalStates.APPROVE.action);
          }
          break;*/
        case modalStates.RECALL.state:
          this.modalComment = getCommentPropertyFromModal(this);
          const allValidRecall = [
            ...this.template.querySelectorAll('lightning-input'),
          ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
          }, true);
          if (allValidRecall) {
            this.processStepApexCall(modalStates.RECALL.action);
          } else {
          }
          
          break;
        case modalStates.REJECT.state:
          this.modalComment = getCommentPropertyFromModal(this);
          const allValid = [
            ...this.template.querySelectorAll('lightning-input'),
          ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
          }, true);
          if (allValid) {
            this.processStepApexCall(modalStates.REJECT.action);
          } else {
          }
  
          
          break;
        default:
          break;
      }
    }
  
    //searches the users based on the lookup component search event.
    handleLookupSearch(event) {
      if (this.isUserBtnSelected) {
        searchUsers(event.detail)
          .then(results => {
            this.template.querySelector("c-lookup").setSearchResults(results);
          })
          .catch(error => {
            this.lookupErrors = [error];
          });
      }
      if (this.isQueueBtnSelected) {
        searchQueue(event.detail)
          .then(results => {
            this.template.querySelector("c-lookup").setSearchResults(results);
          })
          .catch(error => {
            this.lookupErrors = [error];
          });
      }
  
    }
  
    handleSelectionChange() {
      this.lookupErrors = [];
    }
  
    renderedCallback() {
      console.log('Invoking rendered Callback...');
      if (this.currentModalState === modalStates.REASSIGN.state) {
        console.log('Inside Reassign Modal Rendered...');
        let btnList = this.template.querySelectorAll('button');
        btnList.forEach(ele => {
          console.log(ele);
          if (ele.textContent === 'User') {
            console.log('inside User...');
            this.elementUser = ele;
          }
          else if (ele.textContent === 'Queue') {
            this.elementQueue = ele;
          }
          else {
  
          }
        })
      }
    }
  }