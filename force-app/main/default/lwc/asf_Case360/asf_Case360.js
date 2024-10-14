/* eslint-disable no-eval */
/* eslint-disable dot-notation */
import { LightningElement, api, wire, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import overrideCSSFile from '@salesforce/resourceUrl/asf_case360StyleOverride';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { getRequiredFieldExpr } from './asf_CaseConfigExpr';

import { updateRecord, notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';

import CASE_ID from '@salesforce/schema/Case.Id';
import CASE_TECH_SOURCE from '@salesforce/schema/Case.Technical_Source__c';
import CASE_REJECTFLAG from '@salesforce/schema/Case.Reject_Case__c';
import CASE_REJECTEDREASON from '@salesforce/schema/Case.Rejected_Reason__c';
import CASE_REJECTIONREASON from '@salesforce/schema/Case.Rejection_Reason__c';

import getCaseFieldsConfig from '@salesforce/apex/ASF_GetCaseRelatedDetails.getCaseFieldsConfig';
import getStageConfig from '@salesforce/apex/ASF_GetCaseRelatedDetails.getStageConfig';
import getCaseCategoryConfig from '@salesforce/apex/ASF_GetCaseRelatedDetails.getCaseCategoryConfig';
import getDefaultValues from '@salesforce/apex/ASF_GetCaseRelatedDetails.getDefaultValues';
//tst strt
import getCaseRelatedObjName from '@salesforce/apex/ASF_GetCaseRelatedDetails.getCaseRelatedObjName';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import currentId from '@salesforce/user/Id';
import fetchBackwardStages from "@salesforce/apex/ASF_CaseManualStageController.fetchBackwardStages";
import fetchNextManualStages from "@salesforce/apex/ASF_CaseManualStageController.fetchNextManualStages";
import fetchAllManualStagesWithCase from "@salesforce/apex/ASF_CaseManualStageController.fetchAllManualStagesWithCase";
import { publish, MessageContext } from 'lightning/messageService';

import getLatestCaseApprovalDetails from '@salesforce/apex/ASF_GetCaseRelatedDetails.getLatestCaseApprovalRecord';
//import ksc_ReloadRequiredFlag from '@salesforce/label/c.ksc_ReloadRequiredFlag';
import { fireEvent, fireEventNoPageRef, registerListener } from 'c/asf_pubsub'; // Virendra - Instead of LMS moving to pubsub
import executeValidation from '@salesforce/apex/ASF_Case360ParaTamperingHelper.executeValidation';

//Added for Complain Rejection
import { NavigationMixin } from 'lightning/navigation';
//import saveReassign from '@salesforce/apex/CaseProcessingHelper.performCaseAssignments';
import asf_CaseEndStatus from '@salesforce/label/c.ASF_CaseEndStatuses';
import getSrRejectReasons from '@salesforce/apex/ASF_GetCaseRelatedDetails.getRejectionReasons';
import getSrBUReasons from '@salesforce/apex/ASF_GetCaseRelatedDetails.getBUReasons';//PR1030924-224 - Zahed


//Code optimization imports - Nov 2023 - Santanu
import fetchUserAndCaseDetails from '@salesforce/apex/ASF_Case360Controller.fetchUserAndCaseDetails';
import updateCaseWithCaseExtn from '@salesforce/apex/ASF_Case360Controller.updateCaseWithCaseExtn';
import { reduceErrors } from 'c/asf_ldsUtils';
import moveToRequestedStage from '@salesforce/apex/ASF_Case360Controller.moveToRequestedStage';
import moveToNextStage from '@salesforce/apex/ASF_Case360Controller.moveToNextStage';

import { refreshApex } from '@salesforce/apex';

import { registerRefreshContainer, unregisterRefreshContainer, REFRESH_COMPLETE, REFRESH_COMPLETE_WITH_ERRORS, REFRESH_ERROR } from 'lightning/refresh'

//Virendra : Start Here : created separate js and exported functions and using here for searchable Picklist and Multi-select Searchable Picklist.
import { setPicklistFieldValue, conditionalRenderingPicklist, renderingPicklistOnStageAdjustment, hideReadOnlyFields } from './searchPicklistController';
//Virendra : Ends Here.
import {BUSpecificCloseCasePopupHandler} from 'c/asf_Case360JSUtility';
//Label added for PR1030924-43
import UnresolvedCommentsNotReqBUs from '@salesforce/label/c.ABAMC_NonMandatoryUnresCommentsBUs';
import ResolvedReasonsRequired from '@salesforce/label/c.ABC_ResolvedReasonsRequired';

export default class Asf_Case360 extends NavigationMixin(LightningElement) {
    @api recordId;
    caseFieldsMetadata = [];
    currentStep = '';
    stagesData = [];
    caseCategoryConfig = [];
    caseCategoryConfigId;
    caseObj;
    caseDefaultValuesObj;
    cccExternalId;
    caseNature;
    caseType;
    caseSubType;
    //caseLOB;
    cccBU;
    currentStatus;
    caseExtensionRecordId;
    caseExtensionObj;
    flag = true;
    toggleUIView = false;
    defaultFieldValuesMap = new Map();
    defaultTextValuesMap = new Map();
    defaultFieldNames = [];
    defaultFieldValues = [];
    defaultValues = [];
    caseInfoData;
    //caseExtensionFields = {};
    //tst strt
    caseRelObjName;
    currentPageMode;
    currentOwnerId;
    currentUserId = currentId;
    isCurrentUserOwner = false;
    cancelClicked = false;
    tempHide = true;
    showSpinner = false;
    showPreviousStages = false;
    caseStages = [];
    isNextStageManual = false;
    showManualStages = false;
    selectedManualStage;
    caseManualStages;
    isPendingClarification = false;
    showBackButton = false;
    showPrimaryButtons = true;
    isValid = false;
    openClosurePopUp = false;
    showWBGRejetedReason = false;
    rejectedReason = '';
    showPNOReccomendation = false;
    showIODecision = false;
    rejectedDetails = '';
    showAlwaysManualStages = false;

    showSaveAndCloseButton = false;
    showRejectButton = false;
    showManualStagesButton = false
    showManualStagesComp = false;
    isClosedOrRejected = false;
    showSubmitButtons = true;
    fileValidation;
    //tst end

    mapData = [];
    fields2;
    isMoveToStageButtonDisabled = true;
    isMoveToPrevStageButtonDisabled = true;
    isMoveToNextStageButtonDisabled = false;
    rejectButtonDisabled = false;
    backButtonDisabled = false;

    relatedObjectFields = {}
    caseObjectFields = {}
    assetId;
    //Virendra - New Variables declared.
    currentUserProfileName;
    hasRendered = false;
    iCounter = 0;
    hasError;
    caseRelatedUpdated;
    caseRelatedHasError;
    manualStageCalled = false;
    backStageCalled = false;
    rejectCaseCalled = false;
    showManualStagesDropdown = true;

    loading = false;
    hasAssignmentRules;
    selectedAssigneeType;
    selectedUser;
    queueOptions;
    fetchedQueues;
    selectedQueue = [];
    queueSelected;
    showUserLookup = false;
    showGrpComoboBox = false;
    showAssigneeType = false;
    selectedOwner;
    showUserQueueSelection = false;
    attachmentValidation = false;
    userSelected = true;
    showModal = false;
    display = 'display:none;'
    showResult = 'slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click ';
    searchResult = [];
    selectedId = '';//To store User or queue Selection Id;
    selectedValue = '';//To store User or queue Selection name;

    //Virendra : 6th March 2023 : Conditional Rendering Button UI.
    caseApprovalRecord;
    bShowManualStagesCombobox;
    bProcessBasedOnApprovalStage;
    bProcessBasedOnApprovalStageSubmitNext;
    bShowApprovalNextButton;
    bProcessBasedOnApprovalStageReject;
    bApprovalStageShowRejectButton;
    bProcessBasedOnApprovalStageBack;
    bApprovalStageShowBackButton;
    caseRecordDetails;
    caseExtensionRecordDetails;
    isCaseRecordLoaded = false;
    showWhyRecordReadOnlyInfo = false;
    //Virendra : 1 Apr 2023 : Performance fixes - 
    hasPostRenderingDomManupulationDone = false;
    //Start: Added for Complain Rejection
    complainLevel;
    rejectionRTId;
    userManagerIdVal;
    isComplaintNature = false;
    caseBU;
    isRejection = false;
    showLoading = false;
    showRejModal = false;
    ServiceRequestId;
    ManagerId;
    isWbg;
    isActive = true;
    draftStage = 'None';
    objectApiName = 'SR_Rejection__c';
    srRejectionId;
    accessState;
    isReadOnly = false;
    selectedReason = '';
    reasonLOV = [];
    
    @track resolveReasonLOV = [];//PR1030924-224: ZAHED 
    isLoading = true;//PR1030924-224: ZAHED 
    isOnComplaintReject = false;
    //RejMsg = Rejection_Warning;
    accessState;
    isReadOnly = false;
    selectedReason = '';
    resolutionReason = '';
    isOnComplaintReject = false;
    //RejMsg = Rejection_Warning;

    //ADO-118986
    boolSaveReassignButton = false;
    boolCallSaveReassign = false;

    // VIRENDRA 
    openConfirmFieldPopup = false;
    confirmFieldType = 'text';
    fieldNameToSearch = '';
    fieldConfirmationLWCName = '';
    originalTextValue = '';
    confirmTextValue = '';
    bConfirmationTextNotMatching = true;
    iconClass = '';
    @track caseBusinessUnit='';


    arr_CaseStatuses = [];

    //Adding Save button - Santanu 31 Oct 2023
    skipMoveToNextStage = false;

    refreshContainerID;

    resolutionReasonPopUpFld = ''; //VIRENDRA - ADDED FOR RESOLUTION COMMENT ON POPUP.
    notApplicable = false;
    //Optimization variables
    allowRenderedCallback = false;
    loadReady = false;
    userClickedEditDetails = false;
    processApexReturnValue;
    caseExtensionRecord;
    showForwardStages = false;
    closureTypeSelected = 'resolved';
    selectedStage;
    showErrors = false;
    errorMessage;
    disableSkipSave = true;
    disableBackSave = true;
    get closureTypeOptions() {
        return [
            { label: 'Close Resolved', value: 'resolved' },
            { label: 'Close Unresolved', value: 'unresolved' }
        ];
    }

    UnresolvedCommentsNotReqBUs = UnresolvedCommentsNotReqBUs;
    isNoActionStage = false;
    saveDataOnBack = false;
    ResolvedReasonsRequired = ResolvedReasonsRequired;  

    get eligibleForBU(){
        return !(this.caseBusinessUnit == 'ABSLI');
    }

    get showResolvedReasons(){
        const listOfBUs = this.ResolvedReasonsRequired.split(',');
        if(listOfBUs.includes(this.caseBusinessUnit)){
            return true;
        }else{
            return false;
        }
    }

    //added for PR1030924-43, checking if BU is ABSLAMC, then make the Unresolved remarks field non mandatory
    get optionalResComment(){
        const listOfBUs = this.UnresolvedCommentsNotReqBUs.split(',');
        if(listOfBUs.includes(this.caseBusinessUnit)){
            return false;
        } else{
            return true;
        }
        
    }
    get showRejectPanel() {
        return this.closureTypeSelected == 'unresolved';
    }
    get hasApprovalRecord() {
        return this.caseApprovalRecord != undefined && this.caseApprovalRecord != null;
    }
    get isPendingForApproval() {
        let stgData;
        let caseStage = this.currentStatus;
        if (this.hasApprovalRecord) {
            for (let i in this.stagesData) {
                if (caseStage.trim().toLowerCase() == this.stagesData[i].StageName__c.trim().toLowerCase()) {
                    stgData = this.stagesData[i];
                    break;
                }
            }
            if (stgData && stgData.Is_Approval_Stage__c) {
                let latestCaseApprovalStatus = this.caseApprovalRecord.Approval_Status__c;
                if (latestCaseApprovalStatus.trim().toLowerCase() == 'pending') {
                    return true;
                }
            }
        }
        return false;
    }
    get isCaseAtFirstStage() {
        let currentStageConfig = this.stagesData.filter((item, index) => {
            return item.StageName__c == this.caseObj.Stage__c;
        });
        if (currentStageConfig == undefined || currentStageConfig.length == 0) {
            return false;
        }
        currentStageConfig = currentStageConfig[0];
        return currentStageConfig.Order__c == 1;
    }
    get isCaseAtReopenStage(){
        return this.caseObj.Stage__c == 'Reopened';
    }
    get isReopenWithoutMovement(){
        return this.caseObj.Reopen_Style__c == 'Reopen Stage No Movement';
    }
    get hasManualStagesForward() {
        let currentStageConfig = this.stagesData.filter((item, index) => {
            return item.StageName__c == this.caseObj.Stage__c;
        });
        if (currentStageConfig == undefined || currentStageConfig.length == 0) {
            return false;
        }
        currentStageConfig = currentStageConfig[0];
        let manualStages = this.stagesData.filter((item, index) => {
            return item.Order__c > currentStageConfig.Order__c && item.Manual_Stage__c == true;
        });
        console.log('manualStages', manualStages);
        if (manualStages == undefined || manualStages.length == 0) {
            return false;
        }
        return manualStages.length > 0;
    }

    //Button Visibility getters
    get showEditDetailsButton() {
        // * Page is rendered in read-only mode - toggleUIView = false
        // * Case is not rejected - isRejection = false
        // * Current user is owner - isCurrentUserOwner = true
        // * Case is not in Closed state
        // * Edit mode is not open
        // * Case is not pending for approval
        console.log('In showEditDetailsButton', this.loadReady, this.userClickedEditDetails, this.caseObj.IsClosed, this.isCurrentUserOwner, this.isPendingForApproval);
        return this.loadReady && !this.userClickedEditDetails && !this.caseObj.IsClosed
            && this.isCurrentUserOwner && !this.isPendingForApproval;
    }

    get openEditMode() {
        // * Case is not rejected - isRejection = false
        // * Current user is owner - isCurrentUserOwner = true
        // * Case is not in Closed state
        // * User clicked on Edit Details button
        // * Case is not pending for approval
        return this.loadReady && this.userClickedEditDetails && !this.caseObj.IsClosed
            && this.isCurrentUserOwner && !this.isPendingForApproval && !this.caseObj.Is_Approval_Pending__c && !this.isNoActionStage;
    }

    get displayBackButton() {
        // * Case is not rejected - isRejection = false
        // * Current user is owner - isCurrentUserOwner = true
        // * Case is not in Closed state
        // * User clicked on Edit Details button
        // * Case is not pending for approval
        // * Case is not at first stage
        return this.loadReady && this.userClickedEditDetails && !this.caseObj.IsClosed
            && this.isCurrentUserOwner && !this.isPendingForApproval && !this.isCaseAtFirstStage
            && (!this.isCaseAtReopenStage
            || (this.isCaseAtReopenStage && !this.isReopenWithoutMovement));
    }

    get showSaveButton() {
        // * Case is not rejected - isRejection = false
        // * Current user is owner - isCurrentUserOwner = true
        // * Case is not in Closed state
        // * User clicked on Edit Details button
        // * Case is not pending for approval
        return this.loadReady && this.userClickedEditDetails && !this.caseObj.IsClosed
            && this.isCurrentUserOwner && !this.isPendingForApproval;
    }

    get showMoveToNextButton() {
        // * Case is not rejected - isRejection = false
        // * Current user is owner - isCurrentUserOwner = true
        // * Case is not in Closed state
        // * User clicked on Edit Details button
        // * Case is not pending for approval
        // * Not in Reopen stage
        return this.loadReady && this.userClickedEditDetails && !this.caseObj.IsClosed
            && this.isCurrentUserOwner && !this.isPendingForApproval && !this.isCaseAtReopenStage;
    }

    get showForwardToStageButton() {
        // * Case is not rejected - isRejection = false
        // * Current user is owner - isCurrentUserOwner = true
        // * Case is not in Closed state
        // * User clicked on Edit Details button
        // * Case is not pending for approval
        // * Manual stages present
        return this.showSaveButton && this.hasManualStagesForward;
    }

    get showCancelButton() {
        // * User clicked on Edit Details button
        return this.loadReady && this.userClickedEditDetails;
    }

    get displayCloseButton() {
        // * Case is not rejected - isRejection = false
        // * Current user is owner - isCurrentUserOwner = true
        // * Case is not in Closed state
        // * User clicked on Edit Details button
        // * Case is not pending for approval
        return this.loadReady && this.userClickedEditDetails && !this.caseObj.IsClosed
            && this.isCurrentUserOwner && !this.isPendingForApproval;
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

    @wire(CurrentPageReference) pageRef;
    @wire(MessageContext) messageContext;
    //tst start
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        var mode;
        if (currentPageReference) {
            mode = currentPageReference.state?.mode;
            if (mode == 'edit') {
                this.currentPageMode = 'edit';
            }
        }
    }
    /**
     * This wire function is rewritten consolidating 4 wire methods which were fetching data on the similar lines.
     * Consolidating the methods also omits the possibility of concurrency issues.
     */
    @wire(fetchUserAndCaseDetails, {
        "caseId": "$recordId"
    })
    async processResult(caseResult) {
        this.processApexReturnValue = caseResult;

        if (caseResult.data) {
            this.caseObj = caseResult.data.caseRec;
            this.userManagerIdVal = caseResult.data.userRec.ManagerId;
            this.currentUserProfileName = caseResult.data.userRec.Profile.Name;

            //Variable population
            this.cccExternalId = this.caseObj.CCC_External_Id__c;
            this.currentOwnerId = this.caseObj.OwnerId;
            this.isPendingClarification = this.caseObj.Pending_Clarification__c;
            this.caseType = this.caseObj.Type_Text__c;
            this.caseSubType = this.caseObj.Sub_Type_Text__c;
            this.caseNature = this.caseObj.Nature__c;
            this.caseExtensionRecord = caseResult.data.caseExtnRec;
            // VIRENDRA - ADDED CASEBUSINESSUNIT
            this.caseBusinessUnit = this.caseObj.Business_Unit__c;
            if (this.caseNature == 'Query') {
                this.showSaveAndCloseButton = true;
            }
            if (this.caseNature == 'Complaint' || this.complainLevel == 'L2' || this.complainLevel == 'L3') {
                this.isComplaintNature = true;
            }
            this.currentStep = this.currentStatus = this.caseObj.Stage__c;
            console.log(this.cccExternalId + ' : ' + this.currentStatus);
            this.showPreviousStages = false;
            this.showForwardStages = false;
            this.userClickedEditDetails = false;
            if (this.currentOwnerId == this.currentUserId) {
                this.isCurrentUserOwner = true;
                // IN CASE OF PREFRAMEWORK TO FRAMEWORK CONVERSION - CURRENTPAGEMODE IS RETURNING UNDEFINED.
                if (this.currentPageMode == 'edit' || this.isCurrentUserOwner) {
                    this.toggleUIView = true;
                    // Virendra - For opening form in Edit Mode.
                    this.userClickedEditDetails = true;
                }
            } else {
                this.isCurrentUserOwner = false;
                this.toggleUIView = false;
            }

            let bEndStatus = false;
            if (this.arr_CaseStatuses.includes(this.caseObj.Stage__c)) {
                bEndStatus = true;
            }

            if (bEndStatus || this.isReadOnly) {
                this.toggleUIView = false;
                this.isClosedOrRejected = true;
            } else {
                this.isClosedOrRejected = false;
            }

            //show Reject button on UI 
            if (!this.isClosedOrRejected && this.isCurrentUserOwner) {
                this.showRejectButton = true;
            }

            //this.adjustFieldsOnStageChange();

            this.fetchPreviousStages();
            console.log('fetchPreviousStages done');
            this.fetchAllManualStages();
            console.log('fetchAllManualStages done');

            //FROM renderedCallback
            if (this.cccExternalId == undefined || this.cccExternalId == null) {
                return;
            }
            
            //if (this.caseCategoryConfig == undefined || this.caseCategoryConfig.length < 1) {
                let caseCatConfig = await getCaseCategoryConfig({ cccExtId: this.cccExternalId }).catch((error) => {
                    this.showError('error', 'Unable to fetch Case Category Config', error);
                    return;
                });
                if (caseCatConfig != undefined && caseCatConfig[0] != undefined) {
                    console.log('getCaseCategoryConfig', JSON.stringify(caseCatConfig));
                    this.caseCategoryConfig = caseCatConfig;
                    this.caseCategoryConfigId = this.caseCategoryConfig[0].Id;
                    this.cccBU = this.caseCategoryConfig[0].Business_Unit__c;
                    this.getStages(this.caseCategoryConfigId);
                }
            //}

            if (this.cccExternalId != null && this.cccExternalId != undefined) {
                console.log('cccExternalId found');
                let result = await getCaseFieldsConfig({ cccId: this.cccExternalId, status: this.currentStatus, caseId: this.recordId })
                .catch(error => {
                    console.log(error);
                    this.showError('error', 'Oops! Error occured', error);
                });
                if(result){
                    this.iCounter++;
                    this.caseFieldsMetadata = JSON.parse(JSON.stringify(result));
                    console.log('getCaseFieldsConfig results received', JSON.stringify(result));
                    let caseFieldsCount = 0, extnFieldsCount = 0;
                    for (let item of this.caseFieldsMetadata) {
                        if (item.isCase == true) {
                            caseFieldsCount++;
                        } else {
                            extnFieldsCount++;
                        }
                    }
                    console.log(caseFieldsCount, extnFieldsCount);
                    
                    let isOdd = (caseFieldsCount % 2 == 1);
                    let isOddExtn = (extnFieldsCount % 2 == 1);
                    console.log('isOdd', isOdd, isOddExtn);
                    this.caseFieldsMetadata = this.caseFieldsMetadata.map((item, index) => {
                        if (item.isCase == true) {
                            caseFieldsCount--;
                            if (isOdd && caseFieldsCount == 0) {
                                //last item
                                item['layoutItemSize'] = 12;
                                item['classString'] = 'slds-form-element slds-form-element_horizontal slds-form-element_readonly slds-form-element_1-col strong-text';
                                item['editClassString'] = 'slds-form-element slds-form-element_horizontal slds-form-element_1-col fix-error';
                                item['divEditClass'] = 'slds-col slds-size_1-of-1 slds-form-element slds-form-element_horizontal';
                            } else {
                                item['layoutItemSize'] = 6;
                                item['classString'] = 'slds-form-element slds-form-element_horizontal slds-form-element_readonly strong-text'
                                item['editClassString'] = 'slds-form-element slds-form-element_horizontal';
                                item['divEditClass'] = 'slds-col slds-size_1-of-2 slds-form-element slds-form-element_horizontal'
                            }
                        } else {
                            extnFieldsCount--;
                            if (isOddExtn && item.isCase == undefined && extnFieldsCount == 0) {
                                //last item
                                item['layoutItemSize'] = 12;
                                item['classString'] = 'slds-form-element slds-form-element_horizontal slds-form-element_readonly slds-form-element_1-col strong-text';
                                item['editClassString'] = 'slds-form-element slds-form-element_horizontal slds-form-element_1-col fix-error';
                                item['divEditClass'] = 'slds-col slds-size_1-of-1 slds-form-element slds-form-element_horizontal';
                            } else {
                                item['layoutItemSize'] = 6;
                                item['classString'] = 'slds-form-element slds-form-element_horizontal slds-form-element_readonly strong-text'
                                item['editClassString'] = 'slds-form-element slds-form-element_horizontal';
                                item['divEditClass'] = 'slds-col slds-size_1-of-2 slds-form-element slds-form-element_horizontal';
                            }
                        }
                        return item;
                    });

                    console.log('&&& After manipulation this.caseFieldsMetadata' + JSON.stringify(this.caseFieldsMetadata));
                    getRequiredFieldExpr(this.template, this.caseFieldsMetadata, this.currentStep, this.currentUserProfileName, this.caseRecordDetails, this.caseExtensionRecordDetails);

                    //Virendra : Starts Here : Searchable Picklist/ Multi-Select Searchable Picklist.
                    this.handleSearchPicklistRendering();
                    //Virendra : Ends Here.

                    if (this.defaultFieldValuesMap.size == 0 && this.defaultTextValuesMap.size == 0) {
                        for (var fieldConfig in this.caseFieldsMetadata) {
                            if (this.caseFieldsMetadata[fieldConfig].DefaultValue) {
                                if (this.caseFieldsMetadata[fieldConfig].DefaultType) {
                                    if (this.caseFieldsMetadata[fieldConfig].DefaultType.toString().toUpperCase() == 'STRING') {
                                        this.defaultTextValuesMap.set(this.caseFieldsMetadata[fieldConfig].FieldAPINAme, this.caseFieldsMetadata[fieldConfig].DefaultValue);
                                        this.defaultFieldNames.push(this.caseFieldsMetadata[fieldConfig].FieldAPINAme);
                                        this.defaultValues.push(this.caseFieldsMetadata[fieldConfig].DefaultValue);
                                    }
                                    else if (this.caseFieldsMetadata[fieldConfig].DefaultType.toString().toUpperCase() == 'REFERENCE') {
                                        this.defaultFieldValuesMap.set(this.caseFieldsMetadata[fieldConfig].FieldAPINAme, this.caseFieldsMetadata[fieldConfig].DefaultValue);
                                        this.defaultFieldNames.push(this.caseFieldsMetadata[fieldConfig].FieldAPINAme);
                                        this.defaultFieldValues.push(this.caseFieldsMetadata[fieldConfig].DefaultValue);
                                    }
                                }
                                else {
                                    this.defaultFieldValuesMap.set(this.caseFieldsMetadata[fieldConfig].FieldAPINAme, this.caseFieldsMetadata[fieldConfig].DefaultValue);
                                    this.defaultFieldNames.push(this.caseFieldsMetadata[fieldConfig].FieldAPINAme);
                                    this.defaultFieldValues.push(this.caseFieldsMetadata[fieldConfig].DefaultValue);
                                }
                            }
                        }
                        console.log('******this.defaultTextValuesMap',this.defaultTextValuesMap);
                        if (this.defaultFieldValuesMap.size > 0) {
                            let result = await getDefaultValues({ caseId: this.recordId, fieldNames: this.defaultFieldNames, fieldValues: this.defaultFieldValues })
                            .catch(error => {
                                console.log(error);
                                this.showError('error', 'Oops! Error occured', error);
                            });
                            if(result){
                                this.caseDefaultValuesObj = result;
                                var revisedList = [];
                                for (var field in this.defaultFieldValues) {
                                    revisedList.push(this.defaultFieldValues[field].replace('case.', ''));
                                }

                                for (var count in revisedList) {
                                    var prop, props = revisedList[count].split('.');
                                    for (var i = 0, iLen = props.length - 1; i < iLen; i++) {
                                        if (i == 0) {
                                            prop = props[i];
                                            this.defaultValues.push(this.caseDefaultValuesObj[prop][props[++i]]);
                                        }
                                    }
                                }
                            }
                        }
                        if(caseFieldsCount == 0){
                            this.isCaseRecordLoaded = true;
                        }
                        if(extnFieldsCount == 0){
                            this.allowRenderedCallback = true;
                        }
                        //this.assignDefaultValues();
                        //moved to renderedCallback
                    }
                }
                
                if (this.caseObj != undefined && this.caseObj != null) {
                    if (this.caseObj.is_Manual_Approval__c == true) {
                        this.getlatestCaseApprovalRecordStatus(this.caseObj.Stage__c);
                    }
                }

                if (this.caseRelObjName == null || this.caseRelObjName == undefined) {
                    this.getCaseRelatedObjName(this.cccExternalId);
                }
            }

            let renderedLightningInputCount = this.template.querySelectorAll('lightning-input-field').length;
            if (renderedLightningInputCount > 1) {
                if (!this.hasPostRenderingDomManupulationDone) {
                    this.adjustFieldsOnStageChange();
                    this.hasPostRenderingDomManupulationDone = true;
                }

            }

            this.loading = false;
            this.loadReady = true;

            //Notify record edit forms about change in data
            let changeArray = [{ recordId: this.recordId }];
            if (this.caseExtensionRecord) {
                changeArray = [...changeArray, { recordId: this.caseExtensionRecord.Id }];
            }
            await notifyRecordUpdateAvailable(changeArray);
        } else if (caseResult.error) {
            this.showError('error', 'Error while loading the case', caseResult.error);
            this.loading = false;
        }
    }

    /** OPTIMIZATION METHODS START */
    /**
     * This method
     */
    saveCaseWithExtension(caseRec, caseExtnRec) {
        console.log('in saveCaseWithExtension');
        updateCaseWithCaseExtn({ caseRec: caseRec, caseExtn: caseExtnRec })
            .then((result) => {
                console.log('saveCaseWithExtension success');
                let toastMsg = this.skipMoveToNextStage ? 'Case updated' : 'Case updated and moved to next stage';
                this.showSuccessMessage('success', toastMsg, '');
                this.handlePublishEvent();
                this.openClosurePopUp = false;
                this.loading = false;
                this.skipMoveToNextStage == false;
                this.loadReady = false;
                getRecordNotifyChange([{ recordId: this.recordId }]);
                refreshApex(this.processApexReturnValue);
                //this.handleSearchPicklistRendering();
            })
            .catch((error) => {
                console.error(error);
                this.showError('error', 'Oops! Error occured', error);
                this.loading = false;
            });
    }

    saveCase(caseRec) {
        console.log('in saveCase');
        updateCaseWithCaseExtn({ caseRec: caseRec, caseExtn: null })
            .then((result) => {
                console.log('saveCase success');
                let toastMsg = this.skipMoveToNextStage ? 'Case updated' : 'Case updated and moved to next stage';
                this.showSuccessMessage('success', toastMsg, '');
                this.handlePublishEvent();
                this.loading = false;
                this.skipMoveToNextStage == false;
                this.loadReady = false;
                refreshApex(this.processApexReturnValue);

                // VIRENDRA - 31 May 2024 - publish Event to invoke LWC on Save.
            })
            .catch((error) => {
                console.error(error);
                this.showError('error', 'Oops! Error occured', error);
                this.loading = false;
            });
    }

    closeTheCase(event) {
        let executeNext = BUSpecificCloseCasePopupHandler(this);
        if(executeNext){
            if (this.closureTypeSelected == 'unresolved') {
                //Checking if Rejection Reason is empty
                const allValid = [
                    ...this.template.querySelectorAll('.ReasonInput'),
                ].reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
                }, true);
                if (allValid) {
                    this.loading = true;
                    const fields = {};
                    fields[CASE_ID.fieldApiName] = this.caseObj.Id;
                    fields[CASE_REJECTFLAG.fieldApiName] = true;
                    fields[CASE_REJECTEDREASON.fieldApiName] = this.rejectedReason;
                    fields[CASE_REJECTIONREASON.fieldApiName] = this.selectedReason;
                    if (this.caseObj.Technical_Source__c == 'API') {
                        fields[CASE_TECH_SOURCE.fieldApiName] = 'LWC';
                    }
                    const recordInput = { fields };
                    updateRecord(recordInput)
                        .then(result => {
                            console.log('Record Rejected Successfully:  ' + JSON.stringify(result));
                            this.openClosurePopUp = false;
                            this.showSuccessMessage('success', "Success", "Case is Rejected");
                            this.handlePublishEvent();
                            this.loading = false;
                            this.loadReady = false;
                            refreshApex(this.processApexReturnValue);
                        })
                        .catch(error => {
                            this.showError('error', 'Oops! Error occured', error);
                            this.loading = false;
                        });
                }
            } else if (this.closureTypeSelected == 'resolved') {
                /* VIRENDRA - ADDED BELOW CHECK TO VALIDATE IF THE RESOLUTION COMMENT IS POPULATED OR NOT */
                const allValid = [
                    ...this.template.querySelectorAll('.ReasonInput'),
                ].reduce((validSoFar, inputCmp) => {
                    inputCmp.reportValidity();
                    return validSoFar && inputCmp.checkValidity();
                }, true);
                if (allValid) {
                    /* IF POPUP LEVEL VALIDATION SUCCESSFUL - CHECK FORM LEVEL VALIDATION AND EXECUTE CASE CLOSURE */
                    let isFormValidated = this.validateFields();
                    if (!isFormValidated) {
                        this.showError('error', 'Mandatory fields missing', 'Please fill all mandatory fields for this stage');
                        return;
                    }
                    this.selectedManualStage = 'Resolved';
                    this.saveManualCaseStage();
    
                }
                /* VALIDATION FOR RESOLUTION COMMENT FIELD ON POPUP DONE ABOVE */
    
    
            } else {
                this.showError('error', 'Please select a closure type to proceed', '');
            }
        }
        
    }

    saveBackCaseStage(event) {
        if(this.selectedStage == null || this.selectedStage == undefined){
            this.showError('error', 'Please select a stage');
            return;
        }
        this.loading = true;
        if(this.saveDataOnBack){
           this.saveDataOnBackStage();
        }else{
            let caseRecord;
            caseRecord = Object.fromEntries([['Id', this.caseObj.Id], ['sobjectType', 'Case']]);
            caseRecord['Stage__c'] = this.selectedStage;
            caseRecord['Pending_Clarification__c'] = true;
            caseRecord['moved_back__c'] = true;
            caseRecord['Is_Manual_Moved__c'] = false;
            if (this.caseObj.Technical_Source__c == 'API') {
                caseRecord['Technical_Source__c'] = 'LWC';
            }
            this.saveCase(caseRecord);
            }
       
    }

    saveDataOnBackStage(){
        //get case record as object from lightning-record-edit-form
         console.log('asmita inside saveDataOnBackStage method');
        let caseRecord;
        let caseElement = this.template.querySelector('lightning-record-edit-form[data-id="caseEditForm"]');
        if (caseElement) {
            let inputFields = [...caseElement.querySelectorAll('lightning-input-field')];
            let fieldsVar = inputFields.map((field) => [field.fieldName, field.value]);
            caseRecord = Object.fromEntries([...fieldsVar, ['Id', this.caseObj.Id], ['sobjectType', 'Case']]);
            caseRecord['Stage__c'] = this.selectedStage;
            caseRecord['Pending_Clarification__c'] = true;
            caseRecord['moved_back__c'] = true;
            caseRecord['Is_Manual_Moved__c'] = false;
            if (this.caseObj.Technical_Source__c == 'API') {
                caseRecord['Technical_Source__c'] = 'LWC';
            }
        }

        //get case extn record as object from lightning-record-edit-form
        let caseExtnRecord;
        let caseExtnElement = this.template.querySelector('lightning-record-edit-form[data-id="caseRelObjEditForm"]');
        if (caseExtnElement) {
            let inputFields = [...caseExtnElement.querySelectorAll('lightning-input-field')];
            let fieldsVar = inputFields.map((field) => [field.fieldName, field.value]);
            caseExtnRecord = Object.fromEntries([...fieldsVar, ['Id', this.caseExtensionRecord.Id]]);
            caseExtnRecord["sobjectType"] = caseExtnElement.objectApiName;
        }
        this.saveCaseWithExtension(caseRecord, caseExtnRecord);
    }

    saveManualCaseStage(event) {
        let isFormValidated = this.validateFields();
        if (isFormValidated) {
            this.manualStageCalled = true;
            this.loading = true;
            this.skipMoveToNextStage = true;

            //get case record as object from lightning-record-edit-form
            let caseRecord;
            let caseElement = this.template.querySelector('lightning-record-edit-form[data-id="caseEditForm"]');
            if (caseElement) {
                let inputFields = [...caseElement.querySelectorAll('lightning-input-field')];
                let fieldsVar = inputFields.map((field) => [field.fieldName, field.value]);
                caseRecord = Object.fromEntries([...fieldsVar, ['Id', this.caseObj.Id], ['sobjectType', 'Case']]);
                caseRecord['Stage__c'] = this.selectedManualStage;
                caseRecord['Pending_Clarification__c'] = false;
                caseRecord['moved_back__c'] = false;
                caseRecord['Is_Manual_Moved__c'] = true;
                if (this.caseObj.Technical_Source__c == 'API') {
                    caseRecord['Technical_Source__c'] = 'LWC';
                }
            }

            //get case extn record as object from lightning-record-edit-form
            let caseExtnRecord;
            let caseExtnElement = this.template.querySelector('lightning-record-edit-form[data-id="caseRelObjEditForm"]');
            if (caseExtnElement) {
                let inputFields = [...caseExtnElement.querySelectorAll('lightning-input-field')];
                let fieldsVar = inputFields.map((field) => [field.fieldName, field.value]);
                caseExtnRecord = Object.fromEntries([...fieldsVar, ['Id', this.caseExtensionRecord.Id]]);
                caseExtnRecord["sobjectType"] = caseExtnElement.objectApiName;
            }
            this.saveCaseWithExtension(caseRecord, caseExtnRecord);
        }
    }

    getStages(ccConfigId) {
        getStageConfig({
            cccId: ccConfigId
        })
            .then(result => {
                this.stagesData = result;
                console.log('tst' + JSON.stringify(this.stagesData));

                if (this.stagesData != null && this.stagesData != undefined) {
                    for (let i in this.stagesData) {
                        if (this.currentStep == this.stagesData[i].StageName__c) {
                            if (this.stagesData[i].hasOwnProperty('Enable_Reassign_Owner__c')
                                && this.stagesData[i].Enable_Reassign_Owner__c == true) {
                                this.boolSaveReassignButton = true;
                            }
                            else {
                                this.boolSaveReassignButton = false;
                            }
                            if(this.stagesData[i].hasOwnProperty('No_Action_stage__c')
                            && this.stagesData[i].No_Action_stage__c == true){
                        console.log('inside hide actions')
                        this.isNoActionStage = true;
                       // this.openEditMode = false;
                        }
                        if(this.stagesData[i].hasOwnProperty('Save_Data_On_Back__c')
                            && this.stagesData[i].Save_Data_On_Back__c == true){
                        console.log('asmita inside save data boolean')
                        this.saveDataOnBack = true;
                       // this.openEditMode = false;
                        }
                        }
                    }
                }
            })
            .catch(error => {
                console.log(error);
                this.showError('error', 'Oops! Error occured', error);
            });

    }
    cancelClose() {
        this.openClosurePopUp = false;
        this.rejectedReason = '';
        this.selectedReason = '';
        this.closureTypeSelected = 'resolved';
        /* VIRENDRA - ADDED TO RESET RESOLUTION COMMENT VARIABLE TO BLANK ON CANCEL */
        this.resolutionReasonPopUpFld = '';

    }
    handleClose(event) {
        //this.fetchRejectionReason();
        this.showRejectModal();
        /* ADDED BELOW CODE TO SET RESOLUTION COMMENT FIELDS VALUE IF IT IS ALREADY POPULATED ON PARENT FORM BEFORE OPENING POP-UP */
        this.template.querySelectorAll('lightning-input-field').forEach(ele => {
            //Resolution_Remarks__c - ABHFL
            //Resolution_Comments__c - ABFL
            //Closure_Comments__c - Payments
            if (ele.fieldName == 'Resolution_Remarks__c' || ele.fieldName == 'Resolution_Comments__c'
             || ele.fieldName == 'Closure_Comments__c') {
                this.resolutionReasonPopUpFld = ele.value;
            }
        })
        /* ENDS HERE */

        this.openClosurePopUp = true;
        // Virendra : 3 Apr 2023 : Performance Fixes.
        this.hasPostRenderingDomManupulationDone = false;
    }
    setRejectedReason(event) {
        this.rejectedReason = event.target.value;
        if (this.rejectedReason && this.rejectedReason.length >255) {
            this.notApplicable=true;
            this.showErrors=true;
            this.errorMessage = 'Length must be less than or equal to 255 characters for Close Unresolved Details';   
        }
        else{
            this.notApplicable=false;
            this.showErrors=false;

        }
    }
    handleRejReasonChange(event) {
        this.selectedReason = event.target.value;
    }
    handleClosureTypeChange(event) {
        this.closureTypeSelected = event.target.value;
    }
    handleEditCancel() {
        this.userClickedEditDetails = false;
    }
    handleForwardStageMove() {
        let isFormValidated = this.validateFields();
        if (isFormValidated) {
            this.showForwardStages = true;
        }
    }
    handleSubmit2(event) {
        event.preventDefault();
        this.loading = true;
        this.hasError = this.validateFields();
        if (this.hasError) {
            //get case record as object from lightning-record-edit-form
            let caseRecord;
            let caseElement = this.template.querySelector('lightning-record-edit-form[data-id="caseEditForm"]');
            if (caseElement) {
                let inputFields = [...caseElement.querySelectorAll('lightning-input-field')];
                let fieldsVar = inputFields.map((field) => [field.fieldName, field.value]);
                caseRecord = Object.fromEntries([...fieldsVar, ['Id', this.caseObj.Id], ['sobjectType', 'Case']]);
                if (this.skipMoveToNextStage == false) {
                    //move to next stage is clicked
                    caseRecord['MoveToNext__c'] = true;
                }
                if (this.caseObj.Technical_Source__c == 'API') {
                    caseRecord['Technical_Source__c'] = 'LWC';
                }
                console.log('caseRecord', JSON.stringify(caseRecord));
            }

            //call server method to save the record
            this.saveCase(caseRecord);
        } else {
            this.loading = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Required Fields Missing',
                    message: 'Please fill all the required fields',
                    variant: 'error',
                }),
            );
        }
    }

    handleSubmitRelatedObject2(event) {
        event.preventDefault();
        this.loading = true;
        this.caseExtensionObj = event.detail.fields;
        let isFormValidated = this.validateFields();

        if (isFormValidated) {
            let caseExtnRec = event.detail.fields;
            //get case extension record as object from lightning-record-edit-form
            if (this.caseExtensionRecordId) {
                caseExtnRec["id"] = this.caseExtensionRecordId;
                console.log('caseExtnRec', JSON.stringify(caseExtnRec));
                let aprManualStg = this.caseObj.is_Manual_Approval__c;


                // VIRENDRA - Commenting executeValidation Step - 
                let element = this.template.querySelector('lightning-record-edit-form[data-id="caseRelObjEditForm"]');
                caseExtnRec["sobjectType"] = element.objectApiName;
                delete caseExtnRec["id"];
                caseExtnRec["Id"] = this.caseExtensionRecordId;
                console.log('caseExtnRec', JSON.stringify(caseExtnRec));

                //get case record as object from lightning-record-edit-form
                let caseRecord;
                let caseElement = this.template.querySelector('lightning-record-edit-form[data-id="caseEditForm"]');
                if (caseElement) {
                    let inputFields = [...caseElement.querySelectorAll('lightning-input-field')];
                    let fieldsVar = inputFields.map((field) => [field.fieldName, field.value]);
                    caseRecord = Object.fromEntries([...fieldsVar, ['Id', this.caseObj.Id], ['sobjectType', 'Case']]);
                    if (this.skipMoveToNextStage == false) {
                        //move to next stage is clicked
                        caseRecord['MoveToNext__c'] = true;
                    }
                    if (this.caseObj.Technical_Source__c == 'API') {
                        caseRecord['Technical_Source__c'] = 'LWC';
                    }
                    console.log('caseRecord', JSON.stringify(caseRecord));
                }
                this.saveCaseWithExtension(caseRecord, caseExtnRec);
                /*
                executeValidation({
                    cccId: this.cccExternalId,
                    status: this.currentStep,
                    caseId: this.recordId,
                    record: caseExtnRec,
                    fieldNames: this.defaultFieldNames,
                    fieldValues: this.defaultValues,
                    extensionObjId: this.caseExtensionRecordId,
                    isManualApprovalStg: aprManualStg
                })
                    .then(result => {
                        //validation successful
                        let element = this.template.querySelector('lightning-record-edit-form[data-id="caseRelObjEditForm"]');
                        caseExtnRec["sobjectType"] = element.objectApiName;
                        delete caseExtnRec["id"];
                        caseExtnRec["Id"] = this.caseExtensionRecordId;
                        console.log('caseExtnRec', JSON.stringify(caseExtnRec));

                        //get case record as object from lightning-record-edit-form
                        let caseRecord;
                        let caseElement = this.template.querySelector('lightning-record-edit-form[data-id="caseEditForm"]');
                        if (caseElement) {
                            let inputFields = [...caseElement.querySelectorAll('lightning-input-field')];
                            let fieldsVar = inputFields.map((field) => [field.fieldName, field.value]);
                            caseRecord = Object.fromEntries([...fieldsVar, ['Id', this.caseObj.Id], ['sobjectType', 'Case']]);
                            if (this.skipMoveToNextStage == false) {
                                //move to next stage is clicked
                                caseRecord['MoveToNext__c'] = true;
                            }
                            if (this.caseObj.Technical_Source__c == 'API') {
                                caseRecord['Technical_Source__c'] = 'LWC';
                            }
                            console.log('caseRecord', JSON.stringify(caseRecord));
                        }

                        //call server method to save the records
                        this.saveCaseWithExtension(caseRecord, caseExtnRec);
                    })
                    .catch(error => {
                        console.error(error);
                        this.loading = false;
                        this.showError('error', 'Trying to update Readonly fields', error);
                        this.isMoveToNextStageButtonDisabled = false;
                        return;
                    })*/
            }
        } else {
            this.loading = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Required Fields Missing',
                    message: 'Please fill all the required fields',
                    variant: 'error',
                }),
            );
        }
    }
    /**
     * Adding Save button - Santanu 31 Oct 2023
     * @param {*} event 
     * Sets skipMoveToNextStage=true which skips the next stage progression on form submit
     */
    saveCaseAndExtn(event) {
        this.skipMoveToNextStage = true;
       /* if(this.caseBusinessUnit = 'ABHI') {
            this.skipMoveToNextStage = false;
        }
        else {
            this.skipMoveToNextStage = true;
        }*/
        this.validateFields();
        this.template.querySelector('.hiddenSubmitBtn').click();
        console.log('submit btn clicked1'+this.caseBusinessUnit);
    }
    handleMoveToNext(event) {
        this.skipMoveToNextStage = false;
        this.validateFields();
        this.template.querySelector('.hiddenSubmitBtn').click();
    }
    cancelBackCaseStage() {
        this.showPreviousStages = false;
        this.selectedStage = undefined;
        this.disableBackSave = true;
    }
    cancelForwardCaseStage() {
        this.showForwardStages = false;
        this.selectedManualStage = undefined;
        this.disableSkipSave = true;
    }
    handlePublishedMessage(payload) {
        console.log('in handlePublishedMessage!!!!!');
        if (payload.source != 'case360' && this.recordId == payload.recordId) {
            console.log('Refreshing now');
            //this.loadReady = false;
            refreshApex(this.processApexReturnValue);
        }
    }
    async handlePublishEvent() {
        //eval("$A.get('e.force:refreshView').fire();");
        let changeArray = [{ recordId: this.recordId }];
        await notifyRecordUpdateAvailable(changeArray);
        let payload = { 'source': 'case360', 'recordId': this.recordId };
        fireEventNoPageRef(this.pageRef, "refreshpagepubsub", payload);
    }
    handleCaseRecordLoad(event) {
        try {
            let formEl = this.template.querySelector('lightning-record-edit-form[data-id="caseEditForm"]');
            let fields = formEl.querySelectorAll('lightning-input-field');
            console.log('fields', fields);
            for (let field of fields) {
                field.value = this.caseObj[field.fieldName];
            }
            console.log('fields extension', fields);

            this.caseRecordDetails = JSON.parse(JSON.stringify(event.detail.records[this.recordId].fields));
            console.log(this.caseRecordDetails);

            this.isCaseRecordLoaded = true;
            this.adjustFieldsOnStageChange();
        }
        catch (error) {
            console.error(error);
        }
    }
    handleRecordLoad(event) {
        try {
            let formEl = this.template.querySelector('lightning-record-edit-form[data-id="caseRelObjEditForm"]');
            let fields = formEl.querySelectorAll('lightning-input-field');
            console.log('fields', fields);
            for (let field of fields) {
                field.value = this.caseExtensionRecord[field.fieldName];
            }
            console.log('fields extension', fields);
            this.caseExtensionRecordDetails = JSON.parse(JSON.stringify(event.detail.records[this.caseExtensionRecord['Id']].fields));
            console.log(this.caseExtensionRecordDetails);
            this.allowRenderedCallback = true;
            this.adjustFieldsOnStageChange();
        }
        catch (error) {
            console.error(error);
        }
    }
    handleCaseRecordLoadReadOnly(event) {
        try {
            let formEl = this.template.querySelector('lightning-record-edit-form[data-id="caseROForm"]');
            let fields = formEl.querySelectorAll('lightning-output-field');
            console.log('fields', fields);
            for (let field of fields) {
                field.value = this.caseObj[field.fieldName];
            }
            console.log('fields extension', fields);

            this.caseRecordDetails = JSON.parse(JSON.stringify(event.detail.records[this.recordId].fields));
            console.log(this.caseRecordDetails);

            this.isCaseRecordLoaded = true;
        } catch (error) {
            console.error(error);
        }
    }
    handleRecordLoadReadOnly(event) {
        try {
            let formEl = this.template.querySelector('lightning-record-edit-form[data-id="caseRelObjROForm"]');
            let fields = formEl.querySelectorAll('lightning-output-field');
            console.log('fields', fields);
            for (let field of fields) {
                field.value = this.caseExtensionRecord[field.fieldName];
            }
            console.log('fields extension', fields);
            this.caseExtensionRecordDetails = JSON.parse(JSON.stringify(event.detail.records[this.caseExtensionRecord['Id']].fields));
            console.log(this.caseExtensionRecordDetails);
        }
        catch (error) {
            console.error(error);
        }
        //this.adjustFieldsOnStageChange();

    }

    renderedCallback() {
        if(this.allowRenderedCallback && this.isCaseRecordLoaded){
            this.allowRenderedCallback = false;
            Promise.all([
                loadStyle(this, overrideCSSFile)
            ]);
            console.log('in renderedCallback');
            
        }
    }
    /** OPTIMIZATION METHODS END */

    fetchManualStages() {
        fetchNextManualStages({ externalID: this.cccExternalId, currentStage: this.caseObj.Stage__c })
            .then(result => {
                console.log('Manual stages', result)
                let stages = [];
                stages = [...result];
                if (stages.length > 0) {
                    this.caseManualStages = stages;
                }
            })
            .catch(error => {
                console.log(error);
                this.showError('error', 'Oops! Error occured', error);
            });
    }
    connectedCallback() {
        console.log('Extension Id =>' + this.caseExtensionRecordId);
        this.loading = true;
        registerListener("refreshpagepubsub", this.handlePublishedMessage, this);
        registerListener("refreshfromIntLWC", this.handleRecordEditFormRefresh, this);
        //this.handlePublishEvent();
        //console.log('starting registerRefresh');
        //this.refreshContainerID = registerRefreshContainer(this, this.refreshContainer);
        this.refreshContainerID = registerRefreshContainer(this.template.host, this.refreshContainer.bind(this));
        //console.log('finished registerRefresh');
        if (asf_CaseEndStatus != null && asf_CaseEndStatus != undefined) {
            this.arr_CaseStatuses = asf_CaseEndStatus.split(',');
        }
    }

    disconnectedCallback() {
        unregisterRefreshContainer(this.refreshContainerID);
    }
    refreshContainer(refreshPromise) {
        console.log("refreshing");
        if (refreshPromise) {
            return refreshPromise
                .then((status) => {
                    if (status === REFRESH_COMPLETE) {
                        console.log("Done!");
                        // Virendra - Refresh the UI when User is changed from Change Owner Button from Detail Page.
                        refreshApex(this.processApexReturnValue);

                        // RENDERING AFTER CHANGE OWNER IS NOT HAPPENING ON WINDOWS MACHINE, MAC WORKING FINE. BELOW CODE TO EXECUTE BASED ON OS.
                        this.handleOSRenderingIssue();

                    } else if (status === REFRESH_COMPLETE_WITH_ERRORS) {
                        console.warn("Done, with issues refreshing some components");
                    } else if (status === REFRESH_ERROR) {
                        console.error("Major error with refresh.");
                    }
                })
                .catch((error) => {
                    console.log(error);
                });
        }
    }


    fetchAllManualStages() {
        fetchAllManualStagesWithCase({ caseId: this.recordId, currentStage : this.caseObj.Stage__c, cccId: this.cccExternalId })
            .then(result => {
                let stages = [];
                // stages = [...result]
                result.forEach((element) => {
                    if (element.value != this.caseObj.Stage__c) {
                        stages.push({
                            label: element.label,
                            value: element.value,
                            noAssignmentRules: element.noAssignmentRules
                        });
                    }
                });
                if (stages.length > 0) {
                    this.caseManualStages = stages;
                    this.caseManualStages.unshift({
                        label: '--None--',
                        value: 'None'
                    });
                    this.showManualStagesDropdown = true;
                    this.selectedManualStage = '';
                }
                else {
                    this.showManualStagesDropdown = false;
                }
            })
            .catch(error => {
                console.log('Manual Stage Error:' + error);
                this.showError('error', 'Oops! Error occured', error);
            });
    }

    getCaseRelatedObjName(cccExtId) {
        getCaseRelatedObjName({ cccId: cccExtId })
            .then(result => {
                if (result) {
                    if (result.includes('__c')) {
                        this.caseRelObjName = result;
                        this.caseExtensionRecordId = this.caseObj[this.caseRelObjName];

                    }
                }

            })
            .catch(error => {
                console.log(error);
                this.showError('error', 'Oops! Error occured', error);
            });
    }

    handleChange(event) {

        // - Virendra - Added below js to separate the original code. Created a Expression Formula field on Case Field Configuration.
        getRequiredFieldExpr(this.template, this.caseFieldsMetadata, this.currentStep, this.currentUserProfileName, this.caseRecordDetails, this.caseExtensionRecordDetails);
        this.handleChangeForSearchPicklist(event);// Virendra - Searchable Picklist code.
        for (var fieldmdt in this.caseFieldsMetadata) {
            //console.log(this.caseFieldsMetadata[fieldmdt]);

            if (this.caseFieldsMetadata[fieldmdt].UpdateAt) {
                if (this.caseFieldsMetadata[fieldmdt].UpdateAt.toString().includes(this.currentStep) && this.caseFieldsMetadata[fieldmdt].ControllingExpression != null && this.caseFieldsMetadata[fieldmdt].ControllingField != null) {
                    if (event.currentTarget.fieldName == this.caseFieldsMetadata[fieldmdt].ControllingField) {

                        if (event.detail.value == this.caseFieldsMetadata[fieldmdt].ControllingExpression) {

                            this.template.querySelectorAll('lightning-input-field').forEach((field) => {
                                if (field.fieldName == this.caseFieldsMetadata[fieldmdt].FieldAPINAme && !this.caseFieldsMetadata[fieldmdt].useControllingFormula) {
                                    field.disabled = false;
                                    //field.required = true;
                                    //var controllingField = this.caseFieldsMetadata.find(item1 => item1.FieldAPINAme == this.caseFieldsMetadata[item].ControllingField);
                                    if (this.caseFieldsMetadata[fieldmdt].RequiredAt) {
                                        if (this.caseFieldsMetadata[fieldmdt].RequiredAt.toString().includes(this.currentStep)) {
                                            field.required = true;
                                        }
                                        else {
                                            field.required = false;
                                        }
                                    }
                                    else {
                                        field.required = false;
                                    }

                                }

                            });
                        }
                        else {
                            this.template.querySelectorAll('lightning-input-field').forEach((field) => {
                                if (field.fieldName == this.caseFieldsMetadata[fieldmdt].FieldAPINAme && !this.caseFieldsMetadata[fieldmdt].useControllingFormula) {
                                    field.disabled = true;
                                    field.required = false;
                                    field.value = '';
                                }

                            });
                        }

                    }
                }
            }
            var regex = new RegExp(/^\d+$/);
            console.log(regex.test(event.target.value));
            this.template.querySelectorAll('lightning-input-field').forEach(element => {
                if (this.caseFieldsMetadata[fieldmdt].FieldAPINAme == event.currentTarget.fieldName) {
                    console.log('inside Number');
                }
            });
        }


    }



    handleSuccess(event) {

        if (!this.manualStageCalled && !this.backStageCalled && !this.rejectCaseCalled) {
            if (this.currentOwnerId == this.currentUserId) {
                this.isCurrentUserOwner = true;
                if (this.currentPageMode == 'edit' && !this.cancelClicked && !this.isReadOnly) {
                    this.toggleUIView = true;
                }

            } else {
                this.isCurrentUserOwner = false;
                this.toggleUIView = false;
            }

            if (event.detail.apiName === 'Case') {
                this.handleSubmit();
            } else {
                if (this.hasError && !this.caseRelatedUpdated) {
                    console.log('tsthaserror onsuccess event recordEditForm', this.hasError);

                    if (!this.caseExtensionRecordId) {
                        this.caseExtensionRecordId = event.detail.id;

                        //Goto Next Stage

                        for (var currentStage in this.stagesData) {

                            let bEndStatus = false;
                            if (this.arr_CaseStatuses.includes(this.currentStep)) {
                                bEndStatus = true;
                            }

                            //if (this.currentStep == this.stagesData[currentStage].Stage_Name__c && this.currentStep != 'Closed' && this.currentStep != 'Rejected') {
                            if (this.currentStep == this.stagesData[currentStage].StageName__c && !bEndStatus) {
                                this.currentStep = this.stagesData[currentStage + 1].StageName__c;
                                break;
                            }
                        }


                        const fields = {};
                        fields[CASE_ID.fieldApiName] = this.caseObj.Id;

                        fields[CASE_TECH_SOURCE.fieldApiName] = 'LWC';

                        const recordInput = { fields };
                        updateRecord(recordInput)
                            .then(result => {
                                console.log('updateresult: 582 ' + JSON.stringify(result));
                                eval("$A.get('e.force:refreshView').fire();");

                            })
                            .catch(error => {
                                console.log('error: ' + JSON.stringify(error));
                            })
                    }
                    else {

                        console.log('case related updated');
                        this.caseRelatedUpdated = true;

                    }
                }
                this.template.querySelector('lightning-record-edit-form[data-id="caseEditForm"]').submit();

            }


        }
        else {
            if (event.detail.apiName != 'Case') {
                this.template.querySelector('lightning-record-edit-form[data-id="caseEditForm"]').submit();

                if (this.manualStageCalled) {

                    this.updateCaseOnManualStageSelection();
                }
                else if (this.backStageCalled) {

                    this.updateCaseOnBackStageSelection();
                }
                else if (this.rejectCaseCalled) {


                }
            }
            else if (event.detail.apiName == 'Case') {

                if (this.rejectCaseCalled) {

                    this.updateCaseOnRejection();
                }

            }
        }


    }

    updateCaseOnManualStageSelection() {

        moveToRequestedStage({
            recordId: this.recordId,
            requestedStage: this.selectedManualStage,
            isForward: true
        }).then((result) => {
            if (this.currentOwnerId == this.currentUserId) {
                this.isCurrentUserOwner = true;
                if (this.currentPageMode == 'edit' && !this.cancelClicked && !this.isReadOnly) {
                    this.toggleUIView = true;
                }

            } else {
                this.isCurrentUserOwner = false;
                this.toggleUIView = false;
            }

            const payload = { recordId: this.recordId };

            this.handlePublishEvent();

            setTimeout(() => {
                eval("$A.get('e.force:refreshView').fire();")
            }, 1000)
            this.showPreviousStages = false;
            this.showBackButton = false;
            this.showPrimaryButtons = true;
            this.toggleUIView = false;
            this.cancelClicked = true;
            const selectedEvent = new CustomEvent('linked', { detail: this.recordId });

            this.dispatchEvent(selectedEvent);

            this.manualStageCalled = false;

            this.isMoveToStageButtonDisabled = true;
            this.isMoveToNextStageButtonDisabled = false;
            this.loading = false;

            this.adjustFieldsOnStageChange();
        }).catch((error) => {
            this.showError('error', 'Oops! Error occured', error);
            this.manualStageCalled = false;
            this.isMoveToStageButtonDisabled = true;
            this.isMoveToNextStageButtonDisabled = false;
            this.loading = false;

            console.log("Error" + JSON.stringify(error));
            if (JSON.stringify(error).includes('Team and Sub Team cannot be blank when moving to')) {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating record',
                        message: 'Team and Sub Team cannot be blank when moving to In Progress with Others stage',
                        variant: 'error',
                    }),
                );
            }
            else if (error.body.pageErrors[0].statusCode.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                console.log('pageErrors');
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating record',
                        message: error.body.pageErrors[0].message,
                        variant: 'error',
                    }),
                );
            }

            else if (error.body.message.includes('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                console.log('FIELD_CUSTOM_VALIDATION_EXCEPTION');
                this.errorMessage = error.body.message.substring(82 + ('FIELD_CUSTOM_VALIDATION_EXCEPTION').length);
                var word = this.errorMessage.replace(': []', '');
                console.log('FIELD_CUSTOM_VALIDATION_EXCEPTIONss', this.errorMessage);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating record',
                        message: word,
                        variant: 'error',
                    }),
                );
            }
            else {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating record',
                        message: error.body.message,
                        variant: 'error',
                    }),
                );
            }
        })
    }

    handleSubmitRelatedObject(event) {
        event.preventDefault();
        this.loading = true;
        this.caseExtensionObj = event.detail.fields;
        this.fetchManualStages(); //purpose????
        let isFormValidated = this.validateFields();

        if (isFormValidated) {
            this.isMoveToNextStageButtonDisabled = true;
            let fields = event.detail.fields;
            if (this.caseExtensionRecordId) {
                fields["id"] = this.caseExtensionRecordId;
                console.log('fields', JSON.stringify(fields));
                let aprManualStg = this.caseObj.is_Manual_Approval__c;
                executeValidation({ cccId: this.cccExternalId, status: this.currentStep, caseId: this.recordId, record: fields, fieldNames: this.defaultFieldNames, fieldValues: this.defaultValues, extensionObjId: this.caseExtensionRecordId, isManualApprovalStg: aprManualStg })
                    .then(result => {
                        //validation successful
                        this.template.querySelector('lightning-record-edit-form[data-id="caseRelObjEditForm"]').submit(fields);
                        // let element = this.template.querySelector('lightning-record-edit-form[data-id="caseRelObjEditForm"]');
                        // fields["sobjectType"] = element.objectApiName;
                        // console.log('fields', JSON.stringify(fields));
                    })
                    .catch(error => {
                        console.error(error);
                        this.loading = false;
                        if (error.body) {
                            this.dispatchEvent(
                                new ShowToastEvent({
                                    title: 'Trying to update Readonly fields',
                                    message: error.body.message,
                                    variant: 'error',
                                }),
                            );
                        }

                        this.isMoveToNextStageButtonDisabled = false;
                    })
            }


        } else {
            this.loading = false;
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Required Fields Missing',
                    message: 'Please fill all the required fields',
                    variant: 'error',
                }),
            );
            this.isMoveToNextStageButtonDisabled = false;
        }

    }
    handleSubmit() {
        let isError = false;
        this.caseRelatedHasError = true;

        this.hasError = this.validateFields();

        if (this.boolCallSaveReassign) {
            this.callSaveReassign();
            return;
        }
        console.log('called twice');
        console.log('tst2256562' + this.hasError);

        if (this.hasError) {

            if (this.caseRelatedHasError) {

                console.log('tst2245' + this.caseObj.Id);
                if (this.skipMoveToNextStage == false) {
                    //saveToNextStage({ recordId: this.caseObj.id })
                    moveToNextStage({
                        recordId: this.caseObj.Id
                    })
                        .then(result => {
                            let stageName = result;
                            this.caseRelatedUpdated = false;
                            this.fetchPreviousStages(stageName);

                            console.log('tst updateresult: ' + JSON.stringify(stageName));

                            this.currentStatus = stageName;
                            console.log('checking UsersIds; ' + this.currentUserId, this.currentOwnerId);
                            if (this.currentOwnerId == this.currentUserId) {
                                this.isCurrentUserOwner = true;
                                if (this.currentPageMode == 'edit' && !this.cancelClicked && !this.isReadOnly) {
                                    this.toggleUIView = true;
                                }
                                // this.toggleUIView = true;
                            } else {
                                this.isCurrentUserOwner = false;
                                this.toggleUIView = false;
                            }
                            this.fetchAllManualStages();
                            const selectedEvent = new CustomEvent('linked', { detail: this.recordId });
                            // Dispatches the event.
                            this.dispatchEvent(selectedEvent);

                            setTimeout(() => {
                                eval("$A.get('e.force:refreshView').fire();");
                            }, 1000);

                            const payload = { recordId: this.recordId };

                            this.handlePublishEvent();


                            this.adjustFieldsOnStageChange();

                            fetchNextManualStages({ externalID: this.cccExternalId, currentStage: stageName })
                                .then(stageData => {
                                    console.log('Manual stages', stageData)
                                    let stages = [];
                                    stages = [...stageData];

                                    if (stages.length > 0) {
                                        this.caseManualStages = stages;
                                    } else {
                                        this.caseManualStages = false;
                                    }
                                    // if (ksc_ReloadRequiredFlag.toUpperCase() == 'TRUE') {
                                    //     window.location.reload();
                                    // }



                                    if (this.currentOwnerId == this.currentUserId) {
                                        this.isCurrentUserOwner = true;
                                        if (this.currentPageMode == 'edit' && !this.cancelClicked && !this.isReadOnly) {
                                            this.toggleUIView = true;
                                        }
                                        // this.toggleUIView = true;
                                    } else {
                                        this.isCurrentUserOwner = false;
                                        this.toggleUIView = false;
                                    }
                                    this.isMoveToNextStageButtonDisabled = false;


                                    for (var currentStage in this.stagesData) {

                                        let bEndStatus = false;
                                        if (this.arr_CaseStatuses.includes(stageName)) {
                                            bEndStatus = true;
                                        }
                                        console.log('this.stagesData' + JSON.stringify(this.stagesData));
                                        console.log('currentStage' + currentStage);
                                        //if (this.currentStep == this.stagesData[currentStage].Stage_Name__c && this.currentStep != 'Closed' && this.currentStep != 'Rejected') {
                                        if (stageName == this.stagesData[currentStage].StageName__c && !bEndStatus) {
                                            console.log('stageName' + stageName);
                                            stageName = this.stagesData[parseInt(currentStage)].StageName__c;
                                            break;
                                        }
                                    }


                                    let bEndStatus = false;
                                    if (this.arr_CaseStatuses.includes(stageName)) {
                                        bEndStatus = true;
                                    }

                                    //if (result.stageName == "Closed" || result.stageName == "Rejected") {
                                    if (bEndStatus) {
                                        this.toggleUIView = false;
                                        this.isClosedOrRejected = true;
                                    }
                                    else {
                                        this.showBackButton = true;
                                    }

                                    // Virendra - Refresh Issue for ABCL
                                    //this.dispatchEvent(new RefreshEvent());
                                    getRecordNotifyChange([{ recordId: this.recordId }]);

                                    refreshApex(this.processApexReturnValue);

                                    setTimeout(() => { this.loading = false; }, 1000);


                                })
                                .catch(error => {
                                    console.log(error);
                                    this.showError('error', 'Oops! Error occured', error);
                                    this.isMoveToNextStageButtonDisabled = false;
                                    setTimeout(() => { this.loading = false; }, 1000);
                                });


                            let bEndStatus = false;
                            if (this.arr_CaseStatuses.includes(stageName)) {
                                bEndStatus = true;
                            }

                            //if (result.stageName == "Closed" || result.stageName == "Rejected") {
                            if (bEndStatus) {
                                this.toggleUIView = false;
                                this.isClosedOrRejected = true;
                            }
                            else {
                                this.showBackButton = true;
                            }


                        })
                        .catch((error) => {
                            console.log(error);
                            this.showError('error', 'Oops! Error occured', error);
                            this.errorMessage = error;
                            isError = true;
                            this.loading = false;


                            this.isMoveToNextStageButtonDisabled = false;
                            this.isMoveToStageButtonDisabled = true;

                            
                        });
                }
                else {
                    //Adding Save button - Santanu 31 Oct 2023
                    this.isMoveToNextStageButtonDisabled = false;
                    this.loading = false;
                    this.skipMoveToNextStage = false;
                }
            }
        }
    }

    validateFields() {

        this.template.querySelectorAll("lightning-input-field").forEach(field => {
            field.reportValidity();
        });
        return [...this.template.querySelectorAll("lightning-input-field")].reduce((validSoFar, field) => {

            return (validSoFar && field.reportValidity());
        }, true);
    }


    updateCaseStatus() {

        const fields = {};
        fields[CASE_ID.fieldApiName] = this.caseObj.Id;
        //fields[CASE_STATUS.fieldApiName] = this.currentStep;
        fields[CASE_TECH_SOURCE.fieldApiName] = 'LWC';
        const recordInput = { fields };
        updateRecord(recordInput)
            .then(result => {
                // console.log('updateresult: ' + JSON.stringify(result));
                eval("$A.get('e.force:refreshView').fire();");
                this.adjustFieldsOnStageChange();
            })
            .catch(error => {
                console.log('error: ' + JSON.stringify(error));
            })
    }

    adjustFieldsOnStageChange() {

        this.assignDefaultValues();
        getRequiredFieldExpr(this.template, this.caseFieldsMetadata, this.currentStep, this.currentUserProfileName, this.caseRecordDetails, this.caseExtensionRecordDetails);
        this.handleSearchPicklistRendering();// Virendra - Searchable Picklist Code

        for (var item in this.caseFieldsMetadata) {
            //console.log(this.caseFieldsMetadata[item]);
            this.template.querySelectorAll('lightning-input-field').forEach((field) => {
                if (field.fieldName == this.caseFieldsMetadata[item].FieldAPINAme) {

                    if (this.caseFieldsMetadata[item].UpdateAt) {
                        if (this.caseFieldsMetadata[item].UpdateAt.includes(this.currentStep)) {
                            if (this.caseFieldsMetadata[item].ControllingField == null && !this.caseFieldsMetadata[item].useControllingFormula) {
                                //Commented the below line to allow FLS to take effect - Santanu
                                //field.disabled = false;
                            }
                            else {
                                //this.ccConfig = this.caseCategoryConfig.find(item => item.Product__c == event.detail.value.toString());
                                var controllingField = this.caseFieldsMetadata.find(item1 => item1.FieldAPINAme == this.caseFieldsMetadata[item].ControllingField);
                                if (this.caseExtensionObj) {
                                    if (this.caseExtensionObj[controllingField.FieldAPINAme] == this.caseFieldsMetadata[item].ControllingExpression && !this.caseFieldsMetadata[item].useControllingFormula) {
                                        field.disabled = false;
                                        //check for mandatory
                                        if (this.caseFieldsMetadata[item].RequiredAt) {
                                            if (this.caseFieldsMetadata[item].RequiredAt.toString().includes(this.currentStep)) {
                                                field.required = true;
                                            }
                                            else {
                                                field.required = false;
                                            }
                                        }
                                    }
                                    else {
                                        if (!this.caseFieldsMetadata[item].useControllingFormula) {
                                            field.disabled = true;
                                        }

                                    }
                                }
                                else {
                                    this.template.querySelectorAll('lightning-input-field').forEach((field1) => {
                                        if (controllingField) {
                                            if (field1.fieldName == controllingField.FieldAPINAme) {

                                                if (field1.value == this.caseFieldsMetadata[item].ControllingExpression && !this.caseFieldsMetadata[item].useControllingFormula) {
                                                    field.disabled = false;

                                                    if (this.caseFieldsMetadata[item].RequiredAt) {
                                                        if (this.caseFieldsMetadata[item].RequiredAt.toString().includes(this.currentStep)) {
                                                            field.required = true;
                                                        }
                                                        else {
                                                            field.required = false;
                                                        }
                                                    }
                                                }
                                                else {
                                                    if (!this.caseFieldsMetadata[item].useControllingFormula) {
                                                        field.disabled = true;
                                                    }
                                                }

                                            }
                                        }

                                    });

                                    //field.disabled = true;
                                }
                            }
                        }
                        else {
                            if (!this.caseFieldsMetadata[item].useControllingFormula) {
                                field.disabled = true;
                            }

                        }
                    }
                    else {
                        if (!this.caseFieldsMetadata[item].useControllingFormula) {
                            field.disabled = true;
                        }

                    }

                    if (this.caseFieldsMetadata[item].RequiredAt) {
                        if (this.caseFieldsMetadata[item].RequiredAt.includes(this.currentStep)) {
                            if (!this.caseFieldsMetadata[item].useControllingFormula) {
                                field.required = true;
                            }
                            else {
                                //field.required = false;
                            }

                        }
                        else {
                            field.required = false;
                        }
                    }
                    else {
                        field.required = false;
                    }
                }

            });

        }
        // Virendra : 1 Apr 2023 : Performance Fixes : Added defensive code to execute only when Manual Approval on Case.
        if (this.caseObj != undefined && this.caseObj != null) {
            if (this.caseObj.is_Manual_Approval__c == true) {
                this.getlatestCaseApprovalRecordStatus(this.caseObj.Stage__c);
            }
        }
    }

    // Invoking on click on Edit Detail button.
    handleClick(event) {
        this.toggleUIView = true;
        this.hasRendered = false;
        this.fetchAllManualStages();
        setTimeout(() => { this.handleSearchPicklistRendering(); }, 100);

        this.hasPostRenderingDomManupulationDone = false;
        this.userClickedEditDetails = true;

    }




    assignDefaultValues() {
        //Assign Default values
        if (this.caseCategoryConfig.length > 0) {
            if (this.currentStep == this.caseCategoryConfig[0].First_Stage__c && this.toggleUIView) {
                this.template.querySelectorAll('lightning-input-field').forEach((field) => {
                    for (var count in this.defaultFieldNames) {
                        if (this.defaultFieldNames[count] == field.fieldName) {
                            //console.log('tst223225' + this.defaultFieldNames[count]);
                            if (this.defaultValues[count]) {
                                //console.log('tst2232256' + this.defaultValues[count]);
                                field.value = this.defaultValues[count];
                            }
                        }
                    }
                    //console.log('field.fieldName', field.fieldName);
                    if (this.defaultTextValuesMap.has(field.fieldName)) {
                        //console.log('field.fieldName in loop', field.fieldName, this.defaultTextValuesMap.get(field.fieldName));
                        field.value = this.defaultTextValuesMap.get(field.fieldName);
                    }
                });


            }
        }
    }


    isInputValid() {
        this.isValid = true;
        let inputFields = this.template.querySelectorAll('.validate');
        inputFields.forEach(inputField => {
            if (!inputField.checkValidity()) {
                inputField.reportValidity();
                this.isValid = false;
            }
            // this.contact[inputField.name] = inputField.value;
        });

    }

    handleBackButtonClick() {
        this.showPreviousStages = true;
        // Virendra : 3 Apr 2023 : Performance Fixes.
        this.hasPostRenderingDomManupulationDone = false;
    }

    handleStageChange(event) {
        this.selectedStage = event.detail.value;
        this.disableBackSave = false;
        if (this.selectedStage) {
            this.isMoveToPrevStageButtonDisabled = false;
        }
    }

    handleManualStageChange(event) {
        this.selectedManualStage = event.detail.value;
        if(this.selectedManualStage && this.selectedManualStage != '' && this.selectedManualStage != 'None'){
            this.disableSkipSave = false;
        }else{
            this.disableSkipSave = true;
        }
        if (this.selectedManualStage == 'None') {

            this.isMoveToStageButtonDisabled = true;
            this.isMoveToNextStageButtonDisabled = false;
        }
        else {
            console.log('Checking the value ', this.caseManualStages.filter(e => e.value === this.selectedManualStage))

            this.isMoveToStageButtonDisabled = false;
            this.isMoveToNextStageButtonDisabled = true;

        }
    }

    cancelManualCaseStage() {
        this.showManualStages = false;
        this.showPrimaryButtons = true;
    }

    handleSaveAndCloseButtonClick() {
        this.isInputValid();
        if (!this.isValid) {
            return;
        }
        closeCase({ recordId: this.recordId })
            .then((result) => {
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Success",
                        message: "SR is Closed",
                        variant: "success"
                    })
                );
                getRecordNotifyChange([{ recordId: this.recordId }]);
                //this.dispatchEvent(new CloseActionScreenEvent());
                const payload = { recordId: this.recordId };
                //publish(this.messageContext, CPF_EventRefresh, payload);
                // Virendra - 20th March 2023 - Commented LMS and moved to pubsub
                this.handlePublishEvent();
                eval("$A.get('e.force:refreshView').fire();")
                this.showPrimaryButtons = true;
            })
            .catch((error) => {
                this.showError('error', 'Oops! Error occured', error);
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: "Error updating Case",
                        message: error.body.message,
                        variant: "error"
                    })
                );
            });
    }

    fetchPreviousStages(caseStage) {
        if (this.caseObj.Id) {
            console.log('I am here 0000');
            fetchBackwardStages({ externalID: this.cccExternalId, currentStage: caseStage ? caseStage : this.caseObj.Stage__c, caseId: this.caseObj.Id })
                .then((result) => {
                    console.log("UUUUUUUUUUUUUUU", result);
                    let stages = [];
                    result.forEach((element) => {
                        stages.push({
                            label: element,
                            value: element
                        });
                    });
                    console.log('I am here 0000 --> ' + stages);
                    this.caseStages = stages;
                })
                .catch((error) => {
                    this.showError('error', 'Oops! Error occured', error);
                    console.log(error);
                });
        }
    }

    handleError(e) {
        console.log('called 1165', e.detail);
        //if(JSON.stringify(e.detail.includes)){}
        if (JSON.stringify(e.detail).includes('Reversal Amount should be less than Trans')) {
            this.template.querySelector('[data-id="message"]').setError('Reversal amount should be less than transaction amount');
        }
        this.hasError = true;
        this.loading = false;
        this.manualStageCalled = false;
        this.backStageCalled = false;
        this.isMoveToNextStageButtonDisabled = false;
        this.isMoveToStageButtonDisabled = false;
        this.rejectCaseCalled = false;
        this.isOnComplaintReject = false;
        return;
    }

    handleErrorRelatedObject(e) {
        console.log('called related error block');
        this.caseRelatedHasError = false;
        this.loading = false;
        this.manualStageCalled = false;
        this.backStageCalled = false;
        this.isMoveToNextStageButtonDisabled = false;
        this.isMoveToStageButtonDisabled = false;
        this.rejectCaseCalled = false;
        this.isOnComplaintReject = false;
        return;
    }

    isNumber(s) {
        for (let i = s.length - 1; i >= 0; i--) {
            const d = s.charCodeAt(i);
            if (d < 48 || d > 57) return false;
        }
        return true;
    }
    handleAssigneeChange(event) {
        this.selectedAssigneeType = event.detail.value;
        if (this.selectedAssigneeType == 'user') {
            this.showUserLookup = true;
            this.showGrpComoboBox = false;
        }
        else if (this.selectedAssigneeType == 'queue') {
            this.showUserLookup = false;
            this.showGrpComoboBox = true;
        }
        console.log('AssigneeType' + this.selectedAssigneeType);
    }
    // handleUserSelection(event) {
    //     this.selectedUser = event.target.value;
    //     this.selectedOwner = event.target.value;
    //     console.log('selectedOwner' + this.selectedOwner);
    // }
    handleQueueChange(event) {
        this.queueSelected = event.detail.value;
        this.selectedOwner = event.detail.value;
        console.log('selectedOwner' + this.selectedOwner);
    }

    /**************************
     * Virendra : 6th March 2023
     * Description : Below code is to show and Hide the buttons and Combo-box based on criteria.
     * If the Approval Stage = true on Case Stage Config object for records CCCExternalId follow below logic, else follow existing logic.
    */

    showHideButtons() {
        let stgData;
        let caseStage = this.currentStatus;

        for (let i in this.stagesData) {
            if (caseStage.trim().toLowerCase() == this.stagesData[i].StageName__c.trim().toLowerCase()) {
                stgData = this.stagesData[i];
                break;
            }
        }
        if (stgData) {
            //Submit & Next Button.
            this.showHideSubmitNextButton(stgData, caseStage);
            //Reject Button.
            this.ShowHideRejectButton(stgData, caseStage);
            // Back Button.
            this.ShowHideBackButton(stgData, caseStage);
            // Manual Stage Combobox
            this.ShowHideManualStageComboBox(stgData, caseStage);
            // Make Record edit form fields Read Only.
            this.MakeAllFieldsReadOnlyWhenCaseApprovalPending(stgData, caseStage);
        }



    }
    showHideSubmitNextButton(stgData, caseStage) {
        if (caseStage.trim().toLowerCase() == stgData.StageName__c.trim().toLowerCase()) {
            if (stgData.Is_Approval_Stage__c && !stgData.Manual_Stage__c && !this.isPendingClarification) {
                // Condition 1 : Approval Stage = True AND Manual Stage = False AND Pending Clarification = False
                if (this.caseApprovalRecord) {
                    if (this.caseApprovalRecord.Approval_Status__c != null && this.caseApprovalRecord.Approval_Status__c != "") {
                        let latestCaseApprovalStatus = this.caseApprovalRecord.Approval_Status__c;
                        if (latestCaseApprovalStatus.trim().toLowerCase() == "approved") {
                            // Show Submit & Next Button.
                            this.bShowApprovalNextButton = true;
                            this.bProcessBasedOnApprovalStageSubmitNext = true;
                        }
                        else if (latestCaseApprovalStatus.trim().toLowerCase() == "rejected" || latestCaseApprovalStatus.trim().toLowerCase() == "recalled" || latestCaseApprovalStatus.trim().toLowerCase() == "pending") {
                            // Hide Submit & Next Button - when Latest case approval is rejected or recalled.
                            this.bShowApprovalNextButton = false;
                            this.bProcessBasedOnApprovalStageSubmitNext = true;
                        }
                    }
                }
                else {
                    // Disable button when No Case Approval record submitted.
                    this.bShowApprovalNextButton = false;
                    this.bProcessBasedOnApprovalStageSubmitNext = true;
                }
            }
            else if (stgData.Is_Approval_Stage__c && (stgData.Manual_Stage__c || this.isPendingClarification)) {
                // Condition 2 : Approval Stage = True AND (Manual Stage = True OR Pending Clarification = True)
                if (this.caseApprovalRecord) {
                    if (this.caseApprovalRecord.Approval_Status__c != null && this.caseApprovalRecord.Approval_Status__c != "") {
                        let latestCaseApprovalStatus = this.caseApprovalRecord.Approval_Status__c;
                        if (latestCaseApprovalStatus.trim().toLowerCase() == "approved" || latestCaseApprovalStatus.trim().toLowerCase() == "recalled") {
                            // Show Submit Button when Case Approved.
                            this.bShowApprovalNextButton = true;
                            this.bProcessBasedOnApprovalStageSubmitNext = true;
                        }
                        else if (latestCaseApprovalStatus.trim().toLowerCase() == "rejected") {
                            // Hide Submit Button when Case Approved.
                            this.bShowApprovalNextButton = false;
                            this.bProcessBasedOnApprovalStageSubmitNext = true;
                        }
                        else {
                            // Hide Submit Button when Case Approved.
                            this.bShowApprovalNextButton = false;
                            this.bProcessBasedOnApprovalStageSubmitNext = true;
                        }

                    }

                }
                else {
                    // Show Submit Button when Manual Approval or Stage Reversal when no Case Approval Record available.
                    this.bShowApprovalNextButton = true;
                    this.bProcessBasedOnApprovalStageSubmitNext = true;
                }

            }
            else {
                this.bProcessBasedOnApprovalStageSubmitNext = false;
            }
        }
    }
    get submitNextButtonVisibility() {
        if (this.bProcessBasedOnApprovalStageSubmitNext) {
            return this.bShowApprovalNextButton;
        }
        else {
            //return this.showSubmitButtons;
            return true;
        }
    }
    ShowHideRejectButton(stgData, caseStage) {
        let arr_AllowedRejectionStatus = ['approved', 'rejected', 'recalled'];
        if (caseStage.trim().toLowerCase() == stgData.StageName__c.trim().toLowerCase()) {
            if (stgData.Is_Approval_Stage__c && !stgData.Manual_Stage__c && !this.isPendingClarification) {
                if (this.caseApprovalRecord) {
                    let latestCaseApprovalStatus = this.caseApprovalRecord.Approval_Status__c;
                    if (arr_AllowedRejectionStatus.indexOf(latestCaseApprovalStatus.trim().toLowerCase()) > -1) {
                        // Show Reject button when - Case Approval Status is Approved, Reject or Recalled.
                        this.bApprovalStageShowRejectButton = true;
                        this.bProcessBasedOnApprovalStageReject = true;
                    }
                    else {
                        // Hide Reject button when - Case Approval Status is not Approved, Reject or Recalled.
                        this.bApprovalStageShowRejectButton = false;
                        this.bProcessBasedOnApprovalStageReject = true;
                    }
                }
                else {
                    //show Reject case button when no case Approval Record Present.
                    this.bApprovalStageShowRejectButton = true;
                    this.bProcessBasedOnApprovalStageReject = true;
                }

            }
            else if (stgData.Is_Approval_Stage__c && (stgData.Manual_Stage__c || this.isPendingClarification)) {
                // Condition 2 : Approval Stage = True AND (Manual Stage = True OR Pending Clarification = True)
                if (this.caseApprovalRecord) {
                    let latestCaseApprovalStatus = this.caseApprovalRecord.Approval_Status__c;
                    if (arr_AllowedRejectionStatus.indexOf(latestCaseApprovalStatus.trim().toLowerCase()) > -1) {
                        // Show Reject button when - Case Approval Status is Approved, Reject or Recalled.
                        this.bApprovalStageShowRejectButton = true;
                        this.bProcessBasedOnApprovalStageReject = true;
                    }
                    else {
                        // Hide Reject button when - Case Approval Status is not Approved, Reject or Recalled.
                        this.bApprovalStageShowRejectButton = false;
                        this.bProcessBasedOnApprovalStageReject = true;
                    }
                }
                else {
                    //show Reject case button when no case Approval Record Present.
                    this.bApprovalStageShowRejectButton = true;
                    this.bProcessBasedOnApprovalStageReject = true;
                }
            }
            else {
                this.bProcessBasedOnApprovalStageReject = false;
            }

        }
    }
    get rejectButtonVisibility() {
        if (this.bProcessBasedOnApprovalStageReject) {
            return this.bApprovalStageShowRejectButton;
        }
        else {
            return this.showRejectButton;
        }
    }

    ShowHideBackButton(stgData, caseStage) {
        let arr_AllowedRejectionStatus = ['approved', 'rejected', 'recalled'];
        if (caseStage.trim().toLowerCase() == stgData.StageName__c.trim().toLowerCase()) {
            if (stgData.Is_Approval_Stage__c && !stgData.Manual_Stage__c && !this.isPendingClarification) {
                if (this.caseApprovalRecord) {
                    let latestCaseApprovalStatus = this.caseApprovalRecord.Approval_Status__c;
                    if (arr_AllowedRejectionStatus.indexOf(latestCaseApprovalStatus.trim().toLowerCase()) > -1) {
                        // Show Back button when Case Approval is Approved, Rejected, Recalled.
                        this.bApprovalStageShowBackButton = true;
                        this.bProcessBasedOnApprovalStageBack = true;
                    }
                    else {
                        // Hide Back button when Case Approval is pending for approval
                        this.bApprovalStageShowBackButton = false;
                        this.bProcessBasedOnApprovalStageBack = true;
                    }
                }
                else {
                    //Show back button when no Case Approval Record against Case.
                    this.bApprovalStageShowBackButton = true;
                    this.bProcessBasedOnApprovalStageBack = true;
                }
            }
            else if (stgData.Is_Approval_Stage__c && (stgData.Manual_Stage__c || this.isPendingClarification)) {
                if (this.caseApprovalRecord) {
                    let latestCaseApprovalStatus = this.caseApprovalRecord.Approval_Status__c;
                    if (arr_AllowedRejectionStatus.indexOf(latestCaseApprovalStatus.trim().toLowerCase()) > -1) {
                        // Show Back button when Case Approval is Approved, Rejected, Recalled.
                        this.bApprovalStageShowBackButton = true;
                        this.bProcessBasedOnApprovalStageBack = true;
                    }
                    else {
                        // Hide Back button when Case Approval is pending for approval
                        this.bApprovalStageShowBackButton = false;
                        this.bProcessBasedOnApprovalStageBack = true;
                    }
                }
                else {
                    //Show back button when no Case Approval Record against Case.
                    this.bApprovalStageShowBackButton = true;
                    this.bProcessBasedOnApprovalStageBack = true;
                }
            }
            else {
                this.bProcessBasedOnApprovalStageBack = false;
            }

        }
    }
    get backButtonVisibility() {
        /*if (this.bProcessBasedOnApprovalStageBack && !(this.isPendingClarification)) {
            return this.bApprovalStageShowBackButton;
        }*/
        if (this.bProcessBasedOnApprovalStageBack) {
            return this.bApprovalStageShowBackButton;
        }
        else {
            for (let i in this.stagesData) {
                if (this.currentStep == this.stagesData[i].StageName__c) {

                    let bEndStatus = false;
                    if (this.arr_CaseStatuses.includes(this.currentStep)) {
                        bEndStatus = true;
                    }

                    if (this.stagesData[i].Order__c == 1 || this.stagesData[i].Order__c == "1'") {
                        this.showBackButton = false;
                    }
                    else if (bEndStatus) {
                        this.showBackButton = false;
                    }
                    else {
                        this.showBackButton = true;
                    }
                }

            }

            return this.showBackButton;
        }
    }
    ShowHideManualStageComboBox(stgData, caseStage) {
        let arr_AllowedRejectionStatus = ['approved', 'rejected', 'recalled'];
        if (caseStage.trim().toLowerCase() == stgData.StageName__c.trim().toLowerCase()) {
            if (stgData.Is_Approval_Stage__c && !stgData.Manual_Stage__c && !this.isPendingClarification) {
                if (this.caseApprovalRecord) {
                    let latestCaseApprovalStatus = this.caseApprovalRecord.Approval_Status__c;
                    if (latestCaseApprovalStatus.trim().toLowerCase() == "approved") {
                        // Show Submit & Next Button.
                        this.bProcessBasedOnApprovalStage = true;
                        this.bShowManualStagesCombobox = true;
                    }
                    else if (latestCaseApprovalStatus.trim().toLowerCase() == "rejected" || latestCaseApprovalStatus.trim().toLowerCase() == "recalled" || latestCaseApprovalStatus.trim().toLowerCase() == "pending") {
                        // Hide Submit & Next Button - when Latest case approval is rejected or recalled.
                        this.bProcessBasedOnApprovalStage = true;
                        this.bShowManualStagesCombobox = false;
                    }
                }
                else {
                    // Hide Combo box when no Approval Request present against Case.
                    this.bProcessBasedOnApprovalStage = true;
                    this.bShowManualStagesCombobox = false;
                }
            }
            else if (stgData.Is_Approval_Stage__c && (stgData.Manual_Stage__c || this.isPendingClarification)) {
                if (this.caseApprovalRecord) {
                    let latestCaseApprovalStatus = this.caseApprovalRecord.Approval_Status__c;
                    if (latestCaseApprovalStatus.trim().toLowerCase() == "approved" || latestCaseApprovalStatus.trim().toLowerCase() == "recalled") {
                        // Show Submit & Next Button.
                        this.bProcessBasedOnApprovalStage = true;
                        this.bShowManualStagesCombobox = true;
                    }
                    else if (latestCaseApprovalStatus.trim().toLowerCase() == "rejected" || latestCaseApprovalStatus.trim().toLowerCase() == "pending") {
                        // Hide Submit & Next Button - when Latest case approval is rejected or recalled.
                        this.bProcessBasedOnApprovalStage = true;
                        this.bShowManualStagesCombobox = false;
                    }
                }
                else {
                    // Show Combo box when no Approval Request present against Case.
                    this.bProcessBasedOnApprovalStage = true;
                    this.bShowManualStagesCombobox = true;
                }
            }
        }

    }
    MakeAllFieldsReadOnlyWhenCaseApprovalPending(stgData, caseStage) {
        if (caseStage.trim().toLowerCase() == stgData.StageName__c.trim().toLowerCase()) {
            if (stgData.Is_Approval_Stage__c && !stgData.Manual_Stage__c && !this.isPendingClarification) {
                if (this.caseApprovalRecord) {
                    let latestCaseApprovalStatus = this.caseApprovalRecord.Approval_Status__c;
                    if (latestCaseApprovalStatus.trim().toLowerCase() == "approved" || latestCaseApprovalStatus.trim().toLowerCase() == "pending") {
                        this.showWhyRecordReadOnlyInfo = true;
                        this.template.querySelectorAll('lightning-input-field').forEach(ele => {
                            if (!ele.disabled) {
                                ele.disabled = true;
                            }

                        });
                    }
                    else {
                        this.showWhyRecordReadOnlyInfo = false;
                    }
                }
                else {
                    this.showWhyRecordReadOnlyInfo = false;
                }

            }
            else if (stgData.Is_Approval_Stage__c && (stgData.Manual_Stage__c || this.isPendingClarification)) {
                this.template.querySelectorAll('lightning-input-field').forEach(ele => {
                    if (this.caseApprovalRecord) {
                        let latestCaseApprovalStatus = this.caseApprovalRecord.Approval_Status__c;
                        if (latestCaseApprovalStatus.trim().toLowerCase() == "approved" || latestCaseApprovalStatus.trim().toLowerCase() == "pending") {
                            this.showWhyRecordReadOnlyInfo = true;
                            this.template.querySelectorAll('lightning-input-field').forEach(ele => {
                                if (!ele.disabled) {
                                    ele.disabled = true;
                                }

                            });
                        }
                        else {
                            this.showWhyRecordReadOnlyInfo = false;
                        }
                    }
                    else {
                        this.showWhyRecordReadOnlyInfo = false;
                    }
                })
            }
            else {
                this.showWhyRecordReadOnlyInfo = false;
            }

        }
    }

    getlatestCaseApprovalRecordStatus(caseStage) {
        getLatestCaseApprovalDetails({ caseId: this.recordId, caseCurrentStage: caseStage })
            .then(result => {
                this.caseApprovalRecord = result;
                this.showHideButtons();
            })
            .catch(error => {
                console.error(error);
            })
    }
    get ShowHideManualStageCombo() {
        if (this.bProcessBasedOnApprovalStage) {
            return this.bShowManualStagesCombobox;
        }
        else {
            return this.showManualStages;
        }
    }
    get ShowcaseManualStages() {
        if (this.bProcessBasedOnApprovalStage) {
            return this.bShowManualStagesCombobox;
        }
        else {
            return this.caseManualStages;
        }
    }


    //Start: Added for Complain Rejection
    handleRejectOnComplain(event) {
        //Start: Save SR Details
        this.isOnComplaintReject = true;
        this.saveRejection1(event);
        this.loading = false;
        //End: Save SR Details
        var isWBGVal = false;
        if (this.caseBU == 'WBG') {
            this.userManagerIdVal = '';
            isWBGVal = true;
        }
        this.ServiceRequestId = this.recordId;
        this.ManagerId = this.userManagerIdVal;
        this.isWbg = isWBGVal;

        //logic to set record type
        var type = this.complainLevel + ' Complaint';
        getRejectionRT({ complainType: type }).then(result => {
            this.rejectionRTId = result;
            this.showRejectModal();
        }).catch(error => {
            console.log('Error: ' + error);
        });

    }

    hideRejModal() {
        this.showRejModal = false;
        this.showLoading = false;
        this.selectedReason = '';
    }
    //PR1030924-224: ZAHED : Added filter condition for wellness case - Start
    
    async showRejectModal() {       
        if(this.showResolvedReasons){           
            try{
             const records = await getSrBUReasons({ cccExternalId: this.cccExternalId });                          
             records.forEach(item => {
                    if(item.Type__c == 'Reject'){
                const optionVal = {
                            label: item.Reason__c,
                            value: item.Reason__c
                };
                this.reasonLOV.push(optionVal);
                    }else if(item.Type__c == 'Resolve'){
                        const optionVal = {
                            label: item.Reason__c,
                            value: item.Reason__c
                        };
                        this.resolveReasonLOV.push(optionVal);
                    }                   
            });
            this.isLoading = false;
            }catch (error) {
                this.dispatchEvent(new ShowToastEvent({ title: 'Error', message: 'Error fetching BU reasons.', variant: 'error'}));
                this.isLoading = false;              
            }
        }else{
            this.fetchRejectionReason();
    }
    }
    //PR1030924-224: ZAHED : Added filter condition for wellness case - End

    handleSuccessRejection(event) {
        this.showRejModal = false
        this.srRejectionId = event.detail.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: this.srRejectionId,
                objectApiName: 'SR_Rejection__c',
                actionName: 'view'
            }
        });
    }

    onRejSubmit(event) {
        event.preventDefault();
        const fields = event.detail.fields;
        fields.Rejection_Reason__c = this.selectedReason;
        if (this.selectedReason != '') {
            this.template.querySelector('lightning-record-edit-form[data-id="rejectionEditForm"]').submit(fields);
        }
    }

    showHideSpinner() {
        this.showLoading = !this.showLoading;
        this.template.querySelectorAll('.RejectionInput').forEach(element => {
            if (!element.reportValidity()) {
                this.showLoading = false;
            }
        });
    }

    // ADO-118988 Method to Handle Save and Reassign
    handleSaveReassign() {
        this.boolCallSaveReassign = true;
        this.toggleUIView = true;
        this.hasPostRenderingDomManupulationDone = false;
    }

    // ADO-118986 Method to Handle Save and Reassign Apex Call
    callSaveReassign() {
        saveReassign({
            recordId: this.caseObj.id, requestedStage: this.caseObj.Stage__c,
            strFunctionality: 'saveReassign', strAdditionalString: ''
        })
            .then(result => {
                this.toggleUIView = false;
                this.showLoading = false;
                this.loading = false;

                if (result != null && result != undefined) {
                    if (result.boolSuccess == true) {
                        window.location.reload();
                    }
                    this.dispatchEvent(new ShowToastEvent({ title: '', message: result.strMessage, variant: result.strToastVariant }));
                }
            })
            .catch((error) => {
                this.dispatchEvent(new ShowToastEvent({ title: '', message: 'An unexpected error occured on executing Owner Assignments. Please contact System Admin.', variant: 'error' }));
            });
    }
    //To get Rejection Reason:
    fetchRejectionReason() {
        getSrRejectReasons({ cccExternalId: this.cccExternalId }).then(result => {
            this.reasonLOV = [];
            result.forEach(reason => {
                const optionVal = {
                    label: reason,
                    value: reason
                };
                this.reasonLOV.push(optionVal);
            });
        }).catch(error => {
            console.log('Error: ' + JSON.stringify(error));
        });
    }


    //End: Added for Complain Rejection


    /* Virendra - Code Specific to Searchable Picklist - Start Here */

    handleSearchPicklistRendering() {
        //on rerendered UI
        if (this.caseFieldsMetadata.length > 0) {
            setTimeout(()=>{
                renderingPicklistOnStageAdjustment(this.template, this.caseFieldsMetadata, this.currentStep, this.caseExtensionRecordDetails, this.caseRecordDetails);
            },200)
            
        }

    }
    handleHiddenFieldChange(event) {
        //this.handleVisibility();
        getRequiredFieldExpr(this.template, this.caseFieldsMetadata, this.currentStep, this.currentUserProfileName, this.caseRecordDetails, this.caseExtensionRecordDetails);
        this.handleSearchPicklistRendering();

    }
    handleChangeForSearchPicklist(event) {
        //Called everytime a field value (Non-Searchable Picklist is changed. This is to cater when Controlling field is change and controlling field is non-searchable picklist field.)
        conditionalRenderingPicklist(event, this.template, this.caseFieldsMetadata, this.currentStep);

    }
    handleHideShowFields(ele) {
        //hideReadOnlyFields(this.template);
        if (ele.disabled == true) {
            if (!ele.className.includes('slds-hide')) {
                ele.classList.add('slds-hide');
            }
        }
        else {
            if (ele.dataset.hiddenpicklist != true && ele.dataset.hiddenpicklist != "true") {
                if (ele.className.includes('slds-hide')) {
                    ele.classList.remove('slds-hide');
                }
            }

        }


    }
    handleSetFieldValue(event) {
        // This handler listens to event from child on picklist value change, and set the record-edit-forms "hidden" field value to correct value.
        setPicklistFieldValue(event, this.template);
        // Evaluate conditional element rendering whenever picklist field seletion changes.
        getRequiredFieldExpr(this.template, this.caseFieldsMetadata, this.currentStep, this.currentUserProfileName, this.caseRecordDetails, this.caseExtensionRecordDetails);

    }

    validateCustomPicklist() {
        var isCustPickError = true;
        this.template.querySelectorAll('c-searchable-picklist').forEach(field => {
            isCustPickError = (isCustPickError && field.validateCustomPicklistField());
        });
        return isCustPickError;
    }

    /* Virendra - Code Specific to Searchable Picklist - Ends Here */

    /* VIRENDRA - RESOLUTION REASON ON POPUP */
    handleResolnCommntChng(event) {
        this.resolutionReasonPopUpFld = event.target.value;
        this.template.querySelectorAll('lightning-input-field').forEach(ele => {
            //Resolution_Remarks__c - ABHFL
            //Resolution_Comments__c - ABFL
            //Closure_Comments__c - Payments
            if (ele.fieldName == 'Resolution_Remarks__c' || ele.fieldName == 'Resolution_Comments__c'
             || ele.fieldName == 'Closure_Comments__c') {
                ele.value = this.resolutionReasonPopUpFld;
            }
        })
    }

    handleOSRenderingIssue(){
        if (navigator.userAgent.indexOf('Mac OS X') != -1) {
            
          } else {
            this.handleSearchPicklistRendering();
          }
        
    }
    async handleImportCompoent(compName){
        const { default: ctor } = await import(compName)
            .catch((err) => {
                console.log("loadDynamicUIAction Error importing component", JSON.stringify(err))
                this.showLWC = false;
            });
            this.componentConstructor = ctor;
    }
    async handleVerifyField(event){
        let bValid = false;
        this.fieldNameToSearch = event.target.getAttribute('data-field-name');
        this.fieldConfirmationLWCName = event.target.getAttribute('data-field-lwc-name');

        let allowPopup = true;
        this.template.querySelectorAll('lightning-input-field').forEach(ele => {
            if(ele.fieldName == this.fieldNameToSearch && ele.disabled){
                allowPopup = false;
            }
        });

        if(this.fieldConfirmationLWCName != null && this.fieldConfirmationLWCName != "" && this.fieldConfirmationLWCName != undefined){
            if(allowPopup == true){
                await this.handleImportCompoent(this.fieldConfirmationLWCName);
                this.openConfirmFieldPopup = true;
            }
            
        }

       

        // INVOKE EVENT HERE.
        
        
        
        //debugger;
    }
    cancelConfirmFieldPopup(event){
        this.openConfirmFieldPopup = false;
        this.fieldNameToSearch = '';
        this.bConfirmationTextNotMatching = true;
    }
    varifyConfirmFieldPopup(event){
        
        this.template.querySelectorAll('lightning-input-field').forEach(ele => {
            if(ele.fieldName == this.fieldNameToSearch){
                ele.value = this.originalTextValue;
                this.cancelConfirmFieldPopup();
                this.handleDynamicComponentOpen();
            }
        });
    }
    handleConfirmTextChange(event){
        let val = event.target.value;
        this.confirmTextValue = val;
        this.confirmationCheck();
    }
    confirmationCheck(){
        if(this.originalTextValue == this.confirmTextValue){
            this.bConfirmationTextNotMatching = false;
            this.iconClass = 'successBtn';
        }
        else{
            this.bConfirmationTextNotMatching = true;
        }
    }
    handleOriginalTextChange(event){
        this.originalTextValue = event.target.value; 
        this.confirmationCheck();
    }
    async handlePreventInput(event){
        /*this.fieldNameToSearch = event.target.getAttribute('data-field-name');
        event.target.value = '';
        event.preventDefault();
        this.openConfirmFieldPopup = true;*/
        event.preventDefault();
        let bValid = false;
        this.fieldNameToSearch = event.target.getAttribute('data-field-name');
        this.fieldConfirmationLWCName = event.target.getAttribute('data-field-lwc-name');

        let allowPopup = true;
        this.template.querySelectorAll('lightning-input-field').forEach(ele => {
            if(ele.fieldName == this.fieldNameToSearch && ele.disabled){
                allowPopup = false;
            }
        });

        if(this.fieldConfirmationLWCName != null && this.fieldConfirmationLWCName != "" && this.fieldConfirmationLWCName != undefined){
            if(allowPopup == true){
                await this.handleImportCompoent(this.fieldConfirmationLWCName);
                this.openConfirmFieldPopup = true;
            }
            
        }
    }

    // VIRENDRA - ADDED TO FIX THE REFRESH ISSUE RELATED TO INTEGRATION LWC PANEL.
    async handleRecordEditFormRefresh(payload){
        
        if (payload.source != 'case360' && this.recordId == payload.recordId) {
            this.showLoading = true;
            this.loadReady = false;
            setTimeout(()=>{
                this.loadReady = true;
                this.showLoading = false;
            },100);

            //this.loadReady = false;
            refreshApex(this.processApexReturnValue);
        }
        
    }

    handleDynamicComponentOpen(){
        console.log('handleDynamicComponentOpen');
        let payload = { 'source': 'case360', 
        'recordId': this.recordId, 
        'componentName': 'c/absli_FetchBankDetails',
        'now' : Date.now() };
        fireEventNoPageRef(this.pageRef, "openLWCFromEvent", payload);
        console.log('fireEventNoPageRef done');
    }

    handleCase360FieldExtn(event){
        let arr_result = event.detail.arr_fieldDetails;
        for(var i=0;i<arr_result.length;i++){
            let record = arr_result[i];
            let fieldApiNm = record.FieldAPINAme;
            let fieldVal = record.fieldValue;
            let result = record.status;

            if(result == 'Success'){
                this.template.querySelectorAll('lightning-input-field').forEach(ele => {
                    if(ele.fieldName == fieldApiNm){
                        ele.value = fieldVal;
                    }
                });
            }
        }
        this.cancelConfirmFieldPopup();
    }
    handleClosureCommentPopup(event){
        this.cancelClose();
    }
    



}