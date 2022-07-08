/**
 * `persistReducer` has a general purpose "migrate" config
 * which will be called after getting stored state
 * but before actually reconciling with the reducer.
 *
 * It can be any function which takes state as an argument and
 * returns a promise to return a new state object.
 */
// https://github.com/rt2zz/redux-persist/blob/master/docs/migrations.md#example-with-createmigrate
const migrations = {
  /*
  // @ts-ignore
  0: (state) => {
    return {
      ...state,
      lists: undefined,
    }
  },
  // @ts-ignore
  1: (state) => {
    return {
      ...state,
      user: initialUserState,
    }
  },
  // @ts-ignore
  2: (state) => {
    return {
      ...state,
      lists: undefined,
    }
  },
  // @ts-ignore
  3: (state) => {
    return {
      ...state,
      lists: initialListsState,
    }
  },
*/
};

export default migrations;
