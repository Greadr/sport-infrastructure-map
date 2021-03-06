import FilterSelect from "./FilterSelect";
import {useCallback, useEffect, useState} from "react";
import {mapAPI} from "../API/methods";
import {Tab, Tabs, TabList, TabPanel} from 'react-tabs';
import {ReactComponent as LayersIcon} from '../images/icons/layers.svg'
import {ReactComponent as ServicesIcon} from '../images/icons/services.svg'
import {ReactComponent as FiltersIcon} from '../images/icons/filters.svg'
import {LoadMarkers, AddLayersWithControl, FilterModelToParams} from './Map'
import SavedLayers from './SavedLayers'

const FiltersMenu = ({setModel, model, setIsLoading, savedLayers, flag, selectedInput, setSelectedInput}) => {
    const fetchSportsTypes = useCallback((filter) => {
        return mapAPI.getFilterValues('kind_sport', filter)
    }, [])

    const fetchSportsZonesTypes = useCallback((filter) => {
        return mapAPI.getFilterValues('type_zone', filter)
    }, [])

    const fetchSportsZonesNames = useCallback((filter) => {
        return mapAPI.getFilterValues('name_zone', filter)
    }, [])

    const fetchOrganizations = useCallback((filter) => {
        return mapAPI.getFilterValues('name_organization', filter)
    }, [])

    const fetchNames = useCallback((filter) => {
        return mapAPI.getFilterValues('name_object', filter)
    }, [])

    const onResetFilters = () => {
        setModel(null)
    }

    const updateMapLayers = async (filterModel) => {
        const params = FilterModelToParams(filterModel);
        setIsLoading(true);

        await LoadMarkers(window.Markers, params);
        await Promise.resolve(AddLayersWithControl(window.LeafletMap, window.Markers, params));

        setIsLoading(false);
        setSelectedInput(0);
    }


    useEffect(() => {
        updateMapLayers(model)
    }, [])

    return (
        <>
            <div className={`Menu`}>
                <Tabs defaultIndex={0} forceRenderTabPanel>
                    <TabList>
                        <Tab>
                        <span className={'tabs-img'}>
                            <FiltersIcon/>
                        </span>
                            <span className={'d-flex align-items-center events-header__item--span'}>
                            ??????????????
                        </span>
                        </Tab>
                        <Tab>
                        <span className={'tabs-img'}>
                            <LayersIcon style={{width: 14, height: 14}}/>
                        </span>
                            <span className={'d-flex align-items-center events-header__item--span'}>
                            ????????
                        </span>
                        </Tab>
                        <Tab>
                        <span className={'tabs-img'}>
                            <ServicesIcon style={{width: 12, height: 12}}/>
                        </span>
                            <span className={'d-flex align-items-center events-header__item--span'}>
                            ??????????????????
                        </span>
                        </Tab>
                    </TabList>
                    <div className='Menu-wrapper'>
                        <TabPanel>
                            <h1>??????????????</h1>
                            <div className={'scroller menu-inner'}>
                                <FilterSelect flag={flag} fetchItems={fetchNames} title={'???????????????????? ????????????'} checkbox={false}
                                              type={'obj_name'} setModel={setModel} model={model}/>
                                <FilterSelect flag={flag} fetchItems={fetchOrganizations} title={'?????????????????????????? ??????????????????????'}
                                              type={'org_id'} setModel={setModel} model={model}/>
                                <FilterSelect flag={flag} fetchItems={fetchSportsZonesNames} title={'???????????????????? ????????'}
                                              checkbox={false} type={'sz_name'} setModel={setModel} model={model}/>
                                <FilterSelect flag={flag} fetchItems={fetchSportsZonesTypes} title={'?????? ???????????????????? ????????'}
                                              type={'sz_type'} setModel={setModel} model={model}/>
                                <FilterSelect flag={flag} fetchItems={fetchSportsTypes} title={'?????? ????????????'} type={'s_kind'}
                                              setModel={setModel} model={model}/>
                                <FilterSelect flag={flag} onlyItems={true} title={'?????????????????????? ?????????????????????? ??????????????'}
                                              type={'buf'} setModel={setModel} model={model}/>
                            </div>
                            <div className={'filter-btns'}>
                                <button className={'filter-apply filter-btn'}
                                        onClick={() => updateMapLayers(model)}
                                >??????????????????
                                </button>
                                <button className={'filter-reset filter-btn'}
                                        onClick={() => onResetFilters()}
                                >????????????????
                                </button>
                            </div>
                        </TabPanel>
                        <TabPanel>
                            <h1>????????</h1>
                            <div className={'scroller menu-inner'}>
                                <div className={'layers-control'}>
                                </div>
                            </div>
                        </TabPanel>
                        <TabPanel>
                            <h1>??????????????????????</h1>
                            <div className={'scroller menu-inner'}>
                                <div className={'services-control'}>
                                </div>
                            </div>
                            <div className={'filter-btns filter-btns--calc'}>
                                <button className={'filter-apply filter-btn'} id='layerBtn'>????????????????????</button>
                            </div>
                            <div className={'saveLayer'} style={{display: 'none'}}>
                                <div className={'select__btn saveLayer__input'} style={{marginBottom: 10}}>
                                    <label className={'select-label'}>
                                        <input placeholder={'???????????????? ????????????????????'} type="text"
                                               className={'select-input saveLayerName'}/>
                                    </label>
                                </div>
                                <button className={'filter-apply filter-btn'} id='saveLayerBtn'>??????????????????</button>
                            </div>
                            {savedLayers && <>
                                <h1>?????????????????????? ????????????????????</h1>
                                <div className={'scroller menu-inner saveLayer__inner'}>
                                    <div className={'services-control savedLayersBtns'} style={{paddingTop: 0}}>
                                        {!!savedLayers.length && 
                                            <SavedLayers 
                                                savedLayers={savedLayers} 
                                                selectedInput={selectedInput} 
                                                setSelectedInput={setSelectedInput}/>}
                                        {savedLayers.length === 0 && <span>?????????????????????? ???????????????????? ???????? ??????. <br/>
                                            ?????? ???????????????????? - ???????????????? ???????????????? ??????????, ?????????????????? ?????????????? ?? ?????????????? "????????????????????".</span>}
                                    </div>
                                </div>
                            </>}
                        </TabPanel>
                    </div>
                </Tabs>
            </div>
        </>
    );
}

export default FiltersMenu;
