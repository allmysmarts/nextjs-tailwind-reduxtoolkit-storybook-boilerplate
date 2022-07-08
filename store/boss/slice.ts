import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { AppState } from 'store';
export interface BossState {
  bossID: string;
}

const initialState: BossState = {
  bossID: '',
};

export const bossSlice = createSlice({
  name: 'boss',
  initialState,
  reducers: {
    setBossID: (state, action: PayloadAction<string>) => {
      state.bossID = action.payload;
    },
  },
});

export const { setBossID } = bossSlice.actions;

type selectBoss = (state: AppState) => BossState;

export const selectBoss: selectBoss = (state: AppState) => state.boss;

export default bossSlice.reducer;
