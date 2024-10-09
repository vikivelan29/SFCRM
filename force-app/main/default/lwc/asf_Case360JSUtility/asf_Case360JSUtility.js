import {absliCloseCasePopup} from './ABSLI_CloseCasePopupHandler';

const BUSpecificCloseCasePopupHandler = (that) => {
    if(that.caseBusinessUnit == 'ABSLI'){
        return absliCloseCasePopup(that);
    }
    else{
        return true;
    }
    
};

export { BUSpecificCloseCasePopupHandler };