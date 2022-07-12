import { useCallback } from 'react';
import type { NextPage } from 'next';
import { useAppDispatch, useAppSelector } from '@store/hooks';
import { selectBoss, setBossID } from '@store/boss/slice';

/**
 * @dev It demonstrates to load state value from redux-store.
 * Please refer to store/boss/slice.ts, that defines boss related states.
 */
const Home: NextPage = () => {
  const dispatch = useAppDispatch();
  const { bossID } = useAppSelector(selectBoss);

  const onClickNext = useCallback(() => {
    dispatch(setBossID(`${Number(bossID) + 1}`));
  }, [bossID]);

  return (
    <div className="p-5">
      <div className="wrapper-example container mx-auto">
        This example demonstrates how to use redux-toolkit.
        <div className="nested-child">Nest child</div>
        <br />
        Please check <q>pages/index.tsx</q> where it uses boss slice as an example.
        <br />
        Please try with refresh, in order to inspect persisted reload.
        <br />
        <br />
        Selected Boss ID: <strong>{bossID}</strong>
        <div>
          <button className="btn-primary text-weight-sample" onClick={onClickNext}>
            Next Boss
          </button>
        </div>
      </div>
    </div>
  );
};

export default Home;
