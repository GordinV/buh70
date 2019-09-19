'use strict';

const PropTypes = require('prop-types');

const React = require('react'),
    styles = require('./page-label-styles');

class PageLabel extends React.PureComponent {
    constructor(props) {
        super(props);
        this.state = {
            disabled: props.disabled
        };

        this.handleClick = this.handleClick.bind(this);

    }

    // will update state if props changed
    static getDerivedStateFromProps(nextProps, prevState) {
        if (nextProps.disabled !== prevState.disabled) {
            return {disabled: nextProps.disabled};
        } else return null;
    }


    handleClick() {
        // обработчик на событие клик, подгружаем связанный документ

        if (this.state.disabled) {
            return;
        }

        let page = this.props.page;

        if (this.props.handlePageClick) {
            this.props.handlePageClick(page);
        }
    }


    render() {
        let page = this.props.page,
            style = Object.assign({},styles.pageLabel, this.props.active  ? {backgroundColor:'white'}: {});

        return <label style={style}
                      disabled={this.state.disabled}
                      ref="pageLabel"
                      onClick={this.handleClick}>
            {page.pageName}
        </label>
    }
}


PageLabel.propTypes = {
    handlePageClick: PropTypes.func,
    page: PropTypes.object.isRequired,
    disabled: PropTypes.bool,
    active: PropTypes.bool
};


PageLabel.defaultProps = {
    disabled: false,
    active: true
};


module.exports = PageLabel;