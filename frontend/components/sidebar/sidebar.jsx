'use strict';

const PropTypes = require('prop-types');

const sideBarStyles = require('./sidebar-styles'),
    React = require('react');


class SideBarContainer extends React.Component {
    constructor(props) {
        super(props);

        this.state = {
            width: props.width,
            contentWidth: '100%',
            show: true,
            toolBar: props.toolbar
        };

        this.btnClickHandler = this.btnClickHandler.bind(this);
    }

    btnClickHandler() {
        let width = this.state.show ? '20px' : this.props.width,
            contentWidth = this.state.show ? '1px' : '100%',
            showContent = !this.state.show;

        this.setState({
            width: width,
            contentWidth: contentWidth,
            show: showContent
        });
    }

    render() {
        let toolBarSymbol = this.state.show ? '<' : '>'; //@todo move to styles file

        //prepaire styles
        let sideBarContainerStyle = Object.assign({}, sideBarStyles.sideBarContainerStyle, {width: this.state.width}, {height: this.props.height}),
            toolBarStyle = Object.assign({},sideBarStyles.toolBarStyle, {visibility: this.props.toolbar ? 'visible': 'hidden'}),
            contentStyle = Object.assign({},sideBarStyles.contentStyle, {visibility: this.state.show ? 'visible': 'hidden'}),
            buttonStyle = Object.assign({},sideBarStyles.buttonStyle, {
                height: this.props.toolbar ? sideBarStyles.buttonStyle.height: '0',
                visibility: this.props.toolbar ? 'visible': 'hidden'
        } );

        return (
            <div id="toolBarContainer" style={sideBarContainerStyle} ref="toolbar">
                <div id='btnBar' style={toolBarStyle} >
                    <input type="button"
                           ref = 'sidebar-button'
                           style={buttonStyle}
                           value={toolBarSymbol}
                           onClick={this.btnClickHandler}
                    />
                </div>
                <div id='content' style={contentStyle} ref='content'>
                    {this.props.children}
                </div>
            </div>
        );
    }

}


SideBarContainer.propTypes = {
    toolbar: PropTypes.bool,
    width: PropTypes.string,
    heigth: PropTypes.string
};

SideBarContainer.defaultProps = {
    toolbar: true,
    width: '100%',
    height: '100%'
};

module.exports = SideBarContainer;