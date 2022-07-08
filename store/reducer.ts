import { combineReducers } from '@reduxjs/toolkit';
import boss from './boss/slice';

const reducer = combineReducers({
  boss,
});

export default reducer;
