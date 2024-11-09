import { LightningElement, api, track } from 'lwc';
    import runIntegration from "@salesforce/apex/ASF_IntegrationsController.runIntegration";
    import pollIntegrationStatus from "@salesforce/apex/ABHI_EndorsementLwcController.getRegistrationComplaintStatuses";
    import { ShowToastEvent } from 'lightning/platformShowToastEvent';
    import { reduceErrors } from 'c/asf_ldsUtils';
    //import { subscribe, unsubscribe } from 'lightning/empApi';
    import { fireEventNoPageRef, registerListener } from 'c/asf_pubsub';
    import {RefreshEvent } from 'lightning/refresh'
    import getCaseRecord from '@salesforce/apex/ABHI_EndorsementLwcController.getCaseRecord';

    export default class Abhi_EndorsementStps extends LightningElement {
        @api recordId;
        @api caseIntId;
        @api intExtId;
        @api selectedAction;
        @api allIntegrations;
        @api caseRecord;
        caseIntId;
        channelName = '/event/Case_Integration_Response__e';
        subscription = {};
        message;
        showSpinner = false;
        currentURL;
        @track submitDisabled = false;

        @track notStartedClass = 'step';
        @track completedClass = 'step completed';
        @track inprogressClass = 'step in-progress';
        @track integrationRecordsStatus;

        @track notStartedIcon = 'icon';
        @track completedIcon = 'icon completed';
        @track inprogressIcon = 'icon in-progress';
        @track successCount = 0;
        @track expectedSuccessCount = 1;

        @track registrationStatus = this.notStartedClass;
    

        @track registrationIcon = this.notStartedIcon;
        @track acknowledgeIcon = this.notStartedIcon;
        @track pendingIcon = this.notStartedIcon;

        @track successfontCSS = 'label loading';
        @track defaultfontCSS = 'label completed'

        @track preloader = 'preloader';
        @track preloaderRegistration ='';
        @track preloaderAcknowledge ='';
        @track preloaderPending ='';

        @track step = '0';
        @track integrationInProgress = false;
        @track loading = true;
        @track integrationFailure = false;
        @track endorsementText = ''; 
        @track statusIcon;
        notStartedIcon = 'utility:info_alt';  
        waitingIcon = 'utility:clock';    
        completedIcon = 'utility:success';
        @track integrationInPending = false;

        async connectedCallback(){
            try {
                const caseRecord = await getCaseRecord({ recordId: this.recordId });
                if (caseRecord && caseRecord.Sub_Type_Text__c) {
                    this.endorsementText = caseRecord.Sub_Type_Text__c; // Set endorsementText
                    this.statusIcon = this.notStartedIcon;
                }
            } catch (error) {
                console.error('Error fetching case record:', error);
            }        
            await pollIntegrationStatus({asfIntExtId : this.selectedAction.id ,caseId : this.recordId})
            .then((result)=>{
                console.log('caseSubtype ',result)
                if(result.registrationStatus == 'Success'){
                    this.registrationStatus = this.completedClass;
                
                }
            
                if(result.registrationStatus == 'Pending'){
                    this.submitDisabled = true;
                    this.statusIcon = this.waitingIcon;
                    this.integrationInPending = true;
                }
                this.loading = false;
                

            })
            .catch((error)=>{
                debugger;
                console.log(error);
            })

        }
        closeModal() {
            const closeEvent = new CustomEvent('closepopup', {});
            this.dispatchEvent(closeEvent);
        }

        async processResponse(result) {
            if (result.status != 'Success') {
                this.showMessage('error', 'Error while running Integration', result.response);
                this.showSpinner = false;
                this.submitDisabled = false;
                this.closeModal();
                //this.handleUnsubscribe();
            }
            else if(result.status == 'Success'){
                this.integrationFailure = false;
                this.integrationInProgress = true;
            // console.log(result.caseIntId);
                this.caseIntId = result.caseIntId;
                this.interval = setInterval(() => {
                    //this.closeModal();
                    //this.handleUnsubscribe();

                    //this.showMessage('Info', 'Info', 'Integration Pending.Kindly check the logs');
                    this.doShortPolling();
                if(this.successCount >= this.expectedSuccessCount){
                        clearInterval(this.interval);
                        this.integrationInProgress = false;
                        this.showSpinner = false;
                        let payload = {'source':'intPanel', 'recordId':this.recordId};
                        fireEventNoPageRef(this.pageRef, "refreshpagepubsub", payload); 
                        this.dispatchEvent(new RefreshEvent());  
                        this.closeModal();
                    }
                }, 2000);
            }
            
        }

        async submit() {
            this.integrationFailure = false;
            let selectedInt = this.allIntegrations.find((el) => el.Id == this.selectedAction.id);
            this.showSpinner = true;
            this.submitDisabled = true;
            
            //this.handleSubscribe();
            if (selectedInt) {
                this.preloaderRegistration = this.preloader;
                await runIntegration({ integ: selectedInt, caseRec: this.caseRecord })
                    .then((result) => {
                        this.processResponse(result);
                        this.statusIcon = this.waitingIcon;
                    })
                    .catch((error) => {
                        console.log(error);
                        this.closeModal();
                        this.showSpinner = false;
                        
                    })
            }
        }
        showMessage(variant, title, message) {
            let errMsg = reduceErrors(message);
            const event = new ShowToastEvent({
                variant: variant,
                title: title,
                message: Array.isArray(errMsg) ? errMsg[0] : errMsg
            });
            this.dispatchEvent(event);
        }

        async doShortPolling(){
            
                await pollIntegrationStatus({asfIntExtId : this.selectedAction.id ,caseId : this.recordId})
                .then((result)=>{
                    //debugger;
                    console.log(result);
                    if(result.registrationStatus == 'Success' && this.registrationStatus != this.completedClass){
                        this.successCount++;
                        this.registrationStatus = this.completedClass;
                        this.registrationIcon = this.completedIcon;
                        this.preloaderRegistration = '';
                        this.preloaderAcknowledge = this.preloader;
                        this.preloaderPending = '';
                        this.step = '1';
                    }

                    if(result.registrationStatus == 'Pending' || result.acknowledgeStatus == 'Pending' || result.pendingStatus == 'Pending'){
                        this.submitDisabled = true;
                    }
                
                    if(result.registrationStatus == 'Failure' || result.acknowledgeStatus == 'Failure' || result.pendingStatus == 'Failure'){
                        this.submitDisabled = false;
                        this.integrationInProgress = false;
                        this.integrationFailure = true;
                        console.log('failing api');
                    }

                })
                .catch((error)=>{
                    debugger;
                    console.log(error);
                })


            
        }
    }