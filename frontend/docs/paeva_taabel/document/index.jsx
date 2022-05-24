'use strict';

const PropTypes = require('prop-types');
const React = require('react');
const DOC_TYPE_ID = 'PAEVA_TAABEL';

const DocRights = require('./../../../../config/doc_rights');
const checkRights = require('./../../../../libs/checkRights');
const DocContext = require('./../../../doc-context.js');

const docRights = DocRights[DOC_TYPE_ID] ? DocRights[DOC_TYPE_ID] : [];


const
    DocumentTemplate = require('../../documentTemplate/index.jsx'),
    InputNumber = require('../../../components/input-number/input-number.jsx'),
    ButtonEdit = require('../../../components/button-register/button-register-edit/button-register-edit.jsx'),
    BtnArvesta = require('../../../components/button-register/button-task/index.jsx'),
    Select = require('../../../components/select/select.jsx'),
    InputDate = require('../../../components/input-date/input-date.jsx'),
    InputText = require('../../../components/input-text/input-text.jsx'),
    TextArea = require('../../../components/text-area/text-area.jsx'),
    DataGrid = require('../../../components/data-grid/data-grid.jsx'),
    ButtonSetAll = require('../../../components/button-register/button-register.jsx'),

    styles = require('./styles');
const Loading = require('./../../../components/loading/index.jsx');

const LIBRARIES = require('./../../../../config/constants')[DOC_TYPE_ID].LIBRARIES;

class PaevaTaabel extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            module: 'lapsed',
            loadedData: false,
            docId: props.docId ? props.docId : Number(props.match.params.docId),
            grupp_id: null,
            kpv: null,
            isRebuild: false,
            isInit: true,
            kogus: 0
        };

        this.renderer = this.renderer.bind(this);
        this.handlePageClick = this.handlePageClick.bind(this);
        this.onClickHandler = this.onClickHandler.bind(this);
        this.handleGridRow = this.handleGridRow.bind(this);
        this.prepaireInitData = this.prepaireInitData.bind(this);
        this.handleGridCellClick = this.handleGridCellClick.bind(this);
        this.btnEditGruppClick = this.btnEditGruppClick.bind(this);
        this.handleHeaderClick = this.handleHeaderClick.bind(this);
        this.checkData = this.checkData.bind(this);

        this.pages = [
            {pageName: 'Päeva taabel', docTypeId: DOC_TYPE_ID}
        ];

        this.subtotals = ['osalemine'];

    }

    componentDidMount() {
        if (!this.state.lapsId && DocContext['laps']) {
            //есть значение ид ребенка
            this.setState({lapsId: DocContext['laps']});
        }
    }


    componentDidUpdate(prevProps, prevState) {
        // обновим справочники ребенка
        if (this.state.lapsId !== prevState.lapsId) {
            const doc = this.refs['document'];
            doc.createLibs();
        }

    }

    render() {
        let filter = this.state.lapsId ? `where lapsid = ${this.state.lapsId}` : '';
        return <DocumentTemplate docId={this.state.docId}
                                 ref='document'
                                 docTypeId={DOC_TYPE_ID}
                                 module={this.state.module}
                                 initData={this.props.initData}
                                 libs={LIBRARIES}
                                 renderer={this.renderer}
                                 handleGridBtnClick={this.handleGridBtnClick}
                                 history={this.props.history}
                                 isDisableSave={!this.state.docId}
                                 isGridDataSave={true}
                                 trigger={this.checkData}

        />
    }

    /**
     * поправит данные для грида
     */
    prepaireInitData(self) {
        if (self.docData.gridData && self.docData.gridData.length && self.docData.noms && self.docData.noms.length) {

            // add column nomid to grid
            self.docData.noms.forEach(nom => {
                let column = self.docData.gridConfig.find(row => row.id == String(nom.nom_id));
                // отсекаем услуги, которые не определены как дневные и те, что уже обрабтаны
                if (nom.teenus && !column) {
                    self.docData.gridConfig.push({
                        id: String(nom.nom_id),
                        name: nom.teenus,
                        width: `50px`,
                        type: "boolean"
                    });
                }
            });

            // кол-во услуг
            self.docData.gridData = self.docData.gridData.map(row => {
                row.noms.forEach(nom => {
                    if (row[String(nom.nom_id)]) {
                        // juba olemas
                    } else {
                        row[String(nom.nom_id)] = !!nom.kogus;
                    }
                });
                return row;
            });
            this.setState({isInit: false});

        }

    }


    /**
     *Вернет кастомные компоненты документа
     */

    renderer(self) {
        let isEditMode = self.state.edited;
        let userRoles = DocContext.userData ? DocContext.userData.roles : [];

        // ждем загрузки библиотек и данных
        if (!self || !self.docData || !self.state.loadedLibs) {
            // не загружены данные
            return (<div style={styles.doc}>
                <Loading label={'Laadimine...'}/>
            </div>);
        }

        // не успевает подгрузиться справочник, перегрузка формы
        if (!self.libs['lapse_grupp'].length) {
            setTimeout(() => {
                this.forceUpdate()
            }, 1);
        }

        if (self.docData && self.docData.gridData && self.docData.gridData.length && (this.state.isInit || !isEditMode)) {
            // преобразовываем данные
            this.prepaireInitData(self);

            // найдем числовые поля и поставим их в массив для передачи в грид для суммирования итогов
            const reg = /^\d+$/; // только номера

            self.docData.gridConfig.forEach(row => {
                if (reg.test(row.id)) {
                    if (!this.subtotals.some(item => item == row.id)) {
                        this.subtotals.push(row.id);
                    }
                }
            });
        }

        this.setState({grupp_id: self.docData.grupp_id, kpv: self.docData.kpv});
        const gridStyle = {...styles.grid.headerTable, ...styles.grid};

        return (
            <div style={styles.doc}>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>
                        <InputDate title='Kuupäev '
                                   name='kpv'
                                   value={self.docData.kpv}
                                   ref='input-kpv'
                                   readOnly={!isEditMode}
                                   disabled={!!self.docData.id}
                                   onChange={self.handleInputChange}/>
                    </div>
                    <div style={styles.docColumn}>
                        <InputText title='Staatus'
                                   name='status'
                                   value={self.docData.status || ''}
                                   ref='input-status'
                                   readOnly={true}/>
                    </div>
                </div>
                <div style={styles.docRow}>
                    <div style={styles.docColumn}>

                        <Select title="Üksus:"
                                name='grupp_id'
                                libs="lapse_grupp"
                                data={self.libs['lapse_grupp']}
                                value={self.docData.grupp_id || 0}
                                defaultValue={self.docData.yksys || ''}
                                ref="select-lapse_grupp"
                                collId={'id'}
                                btnDelete={isEditMode}
                                onChange={self.handleInputChange}
                                disabled={!!self.docData.id}
                                readOnly={!isEditMode}
                        />
                    </div>
                    {!self.docData.id && self.docData.grupp_id && checkRights(userRoles, docRights, 'add') ? (
                        <div style={styles.docColumn}>
                            <BtnArvesta
                                value={'Arvesta taabel ?'}
                                onClick={this.onClickHandler.bind('arvesta')}
                                showDate={false}
                                style={styles.BtnArvesta}
                                ref={`btn-arvesta`}
                                key={`key-arvesta`}
                            />

                        </div>) : null
                    }
                    <div style={styles.docColumn}>
                        {checkRights(userRoles, docRights, 'edit') ?
                            <ButtonEdit
                                ref='btnEdit'
                                value={'Muuda'}
                                onClick={this.btnEditGruppClick}
                                show={!isEditMode}
                                style={styles.btnEdit}
                                disabled={false}
                            /> : null}
                    </div>
                </div>
                {self.docData.id && isEditMode ? (<div style={styles.docRow}>
                    <div style={styles.docColumn}/>
                    <div style={styles.docColumn}>
                        <ButtonSetAll
                            onClick={this.onClickHandler.bind('muuda')}
                            style={styles.ButtonSetAll}
                            value={'Kas muuda Covid veerg väärtus?'}
                            ref={`btn-muuda-covid`}
                            key={`key-muuda-covid`}
                        />
                    </div>
                </div>) : null}
                <div style={styles.docRow}>
                    <DataGrid source='details'
                              gridData={self.docData.gridData}
                              gridColumns={self.docData.gridConfig}
                              showToolBar={false}
                              handleGridRow={this.handleGridRow}
                              onHeaderClick={this.handleHeaderClick}
                              onClick={self.handleGridCellClick}
                              readOnly={!isEditMode}
                              style={gridStyle}
                              isForUpdate={isEditMode}
                              subtotals={this.subtotals}
                              ref="data-grid"/>
                </div>
                {self.docData.id ?
                    <div style={styles.docRow}>
                        <TextArea title="Märkused"
                                  name='muud'
                                  ref="textarea-muud"
                                  onChange={self.handleInputChange}
                                  value={self.docData.muud || ''}
                                  readOnly={!isEditMode}/>
                    </div> : null}
            </div>
        );
    }

    handlePageClick(pageDocTypeId) {
        this.props.history.push(`/lapsed/${pageDocTypeId}`)
    }

    onClickHandler(name, value) {
        if (name == 'arvesta') {
            // действие для кнопки arvesta
            const Doc = this.refs['document'];
            let api = `/newApi/task/arvestaPaevaTaabel`;

            Doc.fetchData('Post', api, {seisuga: this.state.kpv, docId: this.state.grupp_id}).then((response) => {
                if (response.data && response.data.error_code) {
                    Doc.setState({
                        warning: response.data.error_message,
                        warningType: 'error'
                    }, () => {
                        this.forceUpdate();
                    });

                } else {

                    let docId = response.data && response.data.result ? response.data.result : null;
                    if (docId) {
                        // reload / redirect
                        const current = `/lapsed/paeva_taabel/${docId}`;
                        this.props.history.replace(`/reload`);
                        setTimeout(() => {
                            this.props.history.replace(current);
                        });
                    }

                }
            })
        } else {
            const data = this.refs['document'].docData.gridData;
            if (data) {
                // пройти по всем записям и поменять значение наоборот
                data.forEach((row, index) => {
                    if (!row.osalemine) {
                        this.checkData(null, index, 'covid', !row.covid);
                        this.forceUpdate();
                    }
                })
            }
        }
    }

    /**
     * будет вызвана триггером при ихменении. Проврит поля посещаемости и если нет, то проставит нет всем услушам
     * @param self
     */
    checkData(self, idx, columnId, value) {
        const data = this.refs['document'].docData;

        if (columnId && columnId == 'osalemine') {
            if (!data.gridData[idx].osalemine) {
                // обнулить значения всех услуг
                for (let [key, value] of Object.entries(data.gridData[idx])) {
                    if (!isNaN(key) && !!value) {
                        // посещения нет, а значение положительное. меняем
                        data.gridData[idx][key] = !value;
                    }
                }
            }

            if (data.gridData[idx].osalemine && data.gridData[idx].covid) {
                // не может ковид быть, если нет отсутствия
                data.gridData[idx].covid = 0;
            }

        }

        // обработка поля кодид
        if (columnId && columnId == 'covid') {
            if (!data.gridData[idx].osalemine) {
                // если есть посещение, то не может быть ковид
                data.gridData[idx].covid = value;
            } else {
                // не меняем значение ковид, так как есть посещение
                data.gridData[idx].covid = !value;

            }
        }

    }

    handleGridRow(gridEvent) {
        this.setState({gridRowEdit: true, gridRowEvent: gridEvent});
    }

    /**
     * обработчик события клика по колонке
     * @param header
     */
    handleHeaderClick(header) {
        let isEditeMode = this.refs['document'].state.edited;
        if (!isEditeMode) {
            console.log('not in edit mode');
            return;
        }

        let column = header[0].column;
        // проверим на колонку со значением кол-ва услуг
        if (isNaN(Number(column))) {
            console.log('vale verg, ignoreerime');
            return;
        }

        // надо пройти циклом и поменять значение в указанном поле
        const data = this.refs['document'].docData;
        if (data && data.gridData && data.gridData.length) {
            data.gridData.forEach(row => {
                if (row[column] !== null && row[column] !== undefined) {
                    row[column] = !row[column];
                }
            });
        }
    }

    handleGridCellClick(action, docId, idx, columnId) {
        gridData[idx][columnId] = !gridData[idx][columnId];
    }

    /**
     *     /обработчик события клиска на кнопке редактирования группы
     */
    btnEditGruppClick() {
        let docGruppId = this.refs['document'].docData.grupp_id;

        // осуществит переход на карточку
        this.props.history.push(`/${this.state.module}/lapse_grupp/${docGruppId}`);

    }


}

PaevaTaabel.propTypes = {
    docId: PropTypes.number,
    initData: PropTypes.object,
    userData: PropTypes.object,
};

PaevaTaabel.defaultProps = {
    params: {docId: 0},
    initData: {},
    userData: {}
};


module.exports = (PaevaTaabel);