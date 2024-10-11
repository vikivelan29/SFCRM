import {absliCloseCasePopup} from './ABSLI_CloseCasePopupHandler';
import {wellnessCloseCasePopup} from './WELLNESS_CloseCasePopupHandler';
import WellnessBU from '@salesforce/label/c.Wellness_BU';//PR1030924-224 - Zahed

const BUSpecificCloseCasePopupHandler = (that) => {
    if(that.caseBusinessUnit == 'ABSLI'){
        return absliCloseCasePopup(that);
    }
    else if(that.caseBusinessUnit == WellnessBU){
        return wellnessCloseCasePopup(that);
    }
    else{
        return true;
    }
    
};
export { BUSpecificCloseCasePopupHandler };