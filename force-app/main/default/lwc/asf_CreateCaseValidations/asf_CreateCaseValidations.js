import { LightningElement } from 'lwc';
import genFundApiValidationCallout from '@salesforce/apex/ABSLI_CreateCaseValidationsController.genFundApiValidationCallout';
import nomineeChangeCaseCreationValidation from '@salesforce/apex/ABSLI_CreateCaseValidationsController.nomineeChangeCaseCreationValidation';
import duplicatePolicyPrintingValidation from '@salesforce/apex/ABSLI_CreateCaseValidationsController.duplicatePolicyPrintingValidation';
import performUINapiCalloutValidation from '@salesforce/apex/ABSLI_CreateCaseValidationsController.performUINapiCallout';
import penalInterestPayoutSaralHealthValidation from '@salesforce/apex/ABSLI_CreateCaseValidationsController.penalInterestPayoutSaralHealthValidation';
import assignmentIssueTypeValidation from '@salesforce/apex/ABSLI_CreateCaseValidationsController.assignmentIssueTypeValidation';
import changeInInvestorProfileValidation from '@salesforce/apex/ABSLI_CreateCaseValidationsController.changeInInvestorProfileValidation';
import interestWaiverForHOValidation from '@salesforce/apex/ABSLI_CreateCaseValidationsController.interestWaiverForHOValidation';
import reinstatementValidation from '@salesforce/apex/ABSLI_CreateCaseValidationsController.reinstatementValidation';
/**
 * Gen Fund validation method with Apex invocation
 * @param {*} input 
 * @returns instance of ValidationWrapper
 */
const genFundApiValidation = async (input,reqFrom) => {
    try{
        let result = await genFundApiValidationCallout({caseRecord:JSON.stringify(input.fields)});
        if(result){
            //if result is as expected, then
            if(result=='Success'){
                return new ValidationWrapper(true, result);
            }else{
                return new ValidationWrapper(false, result);
            }
           //success response
        }
    } catch(error){
        console.log('genFundApiValidation'+JSON.stringify(error));
        return new ValidationWrapper(false, error.message.body);//error response
    }
}

const nomineeChangeValidation = async (input,reqFrom) => {
    try{
        let result = await nomineeChangeCaseCreationValidation({caseRecord:JSON.stringify(input.fields)});
        if(result){
            //if result is as expected, then
            if(result=='Success'){
                return new ValidationWrapper(true, result);
            }else{
                return new ValidationWrapper(false, result);
            }
           //success response
        }
    } catch(error){
        console.log('nomineeChangeValidation'+JSON.stringify(error));
        return new ValidationWrapper(false, error.message.body);//error response
    }
}

const duplicatePolicyPrinting = async (input,reqFrom) => {
    try{
        let result = await duplicatePolicyPrintingValidation({caseRecord:JSON.stringify(input.fields)});
        if(result){
            //if result is as expected, then
            if(result=='Success'){
                return new ValidationWrapper(true, result);
            }else{
                return new ValidationWrapper(false, result);
            }
           //success response
        }
    } catch(error){
        console.log('duplicatePolicyPrintingValidation'+JSON.stringify(error));
        return new ValidationWrapper(false, error.message.body);//error response
    }
}

const performUINapiCallout = async (input,reqFrom) => {
    try{
        let result = await performUINapiCalloutValidation({caseRecord:JSON.stringify(input.fields)});
        if(result){
            //if result is as expected, then
            if(result=='Success'){
                return new ValidationWrapper(true, result);
            }else{
                return new ValidationWrapper(false, result);
            }
           //success response
        }
    } catch(error){
        console.log('performUINapiCalloutValidation'+JSON.stringify(error));
        return new ValidationWrapper(false, error.message.body);//error response
    }
}

const penalInterestPayoutSaralHealth = async (input,reqFrom) => {
    try{
        let result = await penalInterestPayoutSaralHealthValidation({caseRecord:JSON.stringify(input.fields)});
        if(result){
            //if result is as expected, then
            if(result=='Success'){
                return new ValidationWrapper(true, result);
            }else{
                return new ValidationWrapper(false, result);
            }
           //success response
        }
    } catch(error){
        console.log('penalInterestPayoutSaralHealthValidation'+JSON.stringify(error));
        return new ValidationWrapper(false, error.message.body);//error response
    }
}

const assignmentIssueType = async (input,reqFrom) => {
    try{
        let result = await assignmentIssueTypeValidation({caseRecord:JSON.stringify(input.fields)});
        if(result){
            //if result is as expected, then
            if(result=='Success'){
                return new ValidationWrapper(true, result);
            }else{
                return new ValidationWrapper(false, result);
            }
           //success response
        }
    } catch(error){
        console.log('assignmentIssueTypeValidation'+JSON.stringify(error));
        return new ValidationWrapper(false, error.message.body);//error response
    }
}

const changeInInvestorProfile = async (input,reqFrom) => {
    try{
        let result = await changeInInvestorProfileValidation({caseRecord:JSON.stringify(input.fields)});
        if(result){
            //if result is as expected, then
            if(result=='Success'){
                return new ValidationWrapper(true, result);
            }else{
                return new ValidationWrapper(false, result);
            }
           //success response
        }
    } catch(error){
        console.log('changeInInvestorProfileValidation'+JSON.stringify(error));
        return new ValidationWrapper(false, error.message.body);//error response
    }
}

const interestWaiverForHO = async (input,reqFrom) => {
    try{
        let result = await interestWaiverForHOValidation({caseRecord:JSON.stringify(input.fields)});
        if(result){
            //if result is as expected, then
            if(result=='Success'){
                return new ValidationWrapper(true, result);
            }else{
                return new ValidationWrapper(false, result);
            }
           //success response
        }
    } catch(error){
        console.log('interestWaiverForHOValidation'+JSON.stringify(error));
        return new ValidationWrapper(false, error.message.body);//error response
    }
}

const reinstatementVal = async (input,reqFrom) => {
    try{
        let result = await reinstatementValidation({caseRecord:JSON.stringify(input.fields)});
        if(result){
            //if result is as expected, then
            if(result=='Success'){
                return new ValidationWrapper(true, result);
            }else{
                return new ValidationWrapper(false, result);
            }
           //success response
        }
    } catch(error){
        console.log('reinstatementValidation'+JSON.stringify(error));
        return new ValidationWrapper(false, error.message.body);//error response
    }
}

//include new validation methods inside method export block
export {
    genFundApiValidation,nomineeChangeValidation,duplicatePolicyPrinting,performUINapiCallout,penalInterestPayoutSaralHealth,
    assignmentIssueType,changeInInvestorProfile,interestWaiverForHO,reinstatementVal
}

//---------------FRAMEWORK CODE - DO NOT TOUCH--------------//

/**
 * This is the object structure to be returned from the exported methods
 * @param {*} isSuccess 
 * @param {*} errorMessageForUser 
 */
function ValidationWrapper(isSuccess, errorMessageForUser){
    this.isSuccess = isSuccess;
    this.errorMessageForUser = errorMessageForUser;
}
//export default class Asf_CreateCaseValidations extends LightningElement {}