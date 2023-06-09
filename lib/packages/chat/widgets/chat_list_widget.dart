import 'dart:async';
import 'dart:io' if (kIsWeb) 'dart:html';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../extensions/extensions.dart';
import '../chatview.dart';
import 'chat_groupedlist_widget.dart';
import 'reaction_popup.dart';
import 'reply_popup_widget.dart';

class ChatListWidget extends StatefulWidget {
  const ChatListWidget({
    Key? key,
    required this.chatController,
    required this.onTapMessage,
    required this.chatBackgroundConfig,
    required this.showTypingIndicator,
    required this.showReceiverProfileCircle,
    required this.assignReplyMessage,
    required this.replyMessage,
    this.loadingWidget,
    this.reactionPopupConfig,
    this.messageConfig,
    this.chatBubbleConfig,
    this.profileCircleConfig,
    this.swipeToReplyConfig,
    this.repliedMessageConfig,
    this.typeIndicatorConfig,
    this.replyPopupConfig,
    this.loadMoreData,
    this.isLastPage,
  }) : super(key: key);
  final ChatController chatController;
  final Function(Message message) onTapMessage;
  final ChatBackgroundConfiguration chatBackgroundConfig;
  final Widget? loadingWidget;
  final bool showTypingIndicator;
  final ReactionPopupConfiguration? reactionPopupConfig;
  final bool showReceiverProfileCircle;
  final MessageConfiguration? messageConfig;
  final ChatBubbleConfiguration? chatBubbleConfig;
  final ProfileCircleConfiguration? profileCircleConfig;
  final SwipeToReplyConfiguration? swipeToReplyConfig;
  final RepliedMessageConfiguration? repliedMessageConfig;
  final TypeIndicatorConfiguration? typeIndicatorConfig;
  final ReplyMessage replyMessage;
  final ReplyPopupConfiguration? replyPopupConfig;
  final VoidCallBackWithFuture? loadMoreData;
  final bool? isLastPage;
  final MessageCallBack assignReplyMessage;

  @override
  State<ChatListWidget> createState() => _ChatListWidgetState();
}

class _ChatListWidgetState extends State<ChatListWidget>
    with SingleTickerProviderStateMixin {
  bool _isNextPageLoading = false;
  bool showPopUp = false;
  final GlobalKey<ReactionPopupState> _reactionPopupKey = GlobalKey();

  ChatController get chatController => widget.chatController;

  List<Message> get messageList => chatController.initialMessageList;

  ScrollController get scrollController => chatController.scrollController;

  bool get showTypingIndicator => widget.showTypingIndicator;

  ChatBackgroundConfiguration get chatBackgroundConfig =>
      widget.chatBackgroundConfig;

  FeatureActiveConfig? featureActiveConfig;
  ChatUser? currentUser;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (provide != null) {
      featureActiveConfig = provide!.featureActiveConfig;
      currentUser = provide!.currentUser;
    }
    if (featureActiveConfig?.enablePagination ?? false) {
      scrollController.addListener(_pagination);
    }
  }

  void _initialize() {
    chatController.messageStreamController = StreamController();
    if (!chatController.messageStreamController.isClosed) {
      chatController.messageStreamController.sink.add(messageList);
    }
    if (messageList.isNotEmpty) chatController.scrollToLastMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isNextPageLoading &&
            (featureActiveConfig?.enablePagination ?? false))
          SizedBox(
            height: Scaffold.of(context).appBarMaxHeight,
            child: Center(
              child: widget.loadingWidget ?? const CircularProgressIndicator(),
            ),
          ),
        Expanded(
          child: Stack(
            children: [
              ChatGroupedListWidget(
                onTapMessage: widget.onTapMessage,
                showPopUp: showPopUp,
                showTypingIndicator: showTypingIndicator,
                scrollController: scrollController,
                isEnableSwipeToSeeTime:
                    featureActiveConfig?.enableSwipeToSeeTime ?? true,
                chatBackgroundConfig: widget.chatBackgroundConfig,
                assignReplyMessage: widget.assignReplyMessage,
                showReceiverProfileCircle: widget.showReceiverProfileCircle,
                replyMessage: widget.replyMessage,
                swipeToReplyConfig: widget.swipeToReplyConfig,
                repliedMessageConfig: widget.repliedMessageConfig,
                profileCircleConfig: widget.profileCircleConfig,
                messageConfig: widget.messageConfig,
                chatBubbleConfig: widget.chatBubbleConfig,
                typeIndicatorConfig: widget.typeIndicatorConfig,
                onChatBubbleLongPress: (yCoordinate, xCoordinate, message) {
                  if (featureActiveConfig?.enableReactionPopup ?? false) {
                    _reactionPopupKey.currentState?.refreshWidget(
                      messageId: message.id,
                      xCoordinate: xCoordinate,
                      yCoordinate:
                          yCoordinate < 0 ? -(yCoordinate) - 5 : yCoordinate,
                    );
                    setState(() => showPopUp = true);
                  }
                  if (featureActiveConfig?.enableReplySnackBar ?? false) {
                    _showReplyPopup(
                      message: message,
                      sendByCurrentUser: message.sendBy == currentUser?.id,
                    );
                  }
                },
                onChatListTap: _onChatListTap,
              ),
              if (featureActiveConfig?.enableReactionPopup ?? false)
                ReactionPopup(
                  key: _reactionPopupKey,
                  reactionPopupConfig: widget.reactionPopupConfig,
                  onTap: _onChatListTap,
                  showPopUp: showPopUp,
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _pagination() {
    if (widget.loadMoreData == null || widget.isLastPage == true) return;
    if ((scrollController.position.pixels ==
            scrollController.position.maxScrollExtent) &&
        !_isNextPageLoading) {
      setState(() => _isNextPageLoading = true);
      widget.loadMoreData!()
          .whenComplete(() => setState(() => _isNextPageLoading = false));
    }
  }

  void _showReplyPopup({
    required Message message,
    required bool sendByCurrentUser,
  }) {
    final replyPopup = widget.replyPopupConfig;
    ScaffoldMessenger.of(context)
        .showSnackBar(
          SnackBar(
            duration: const Duration(hours: 1),
            backgroundColor: replyPopup?.backgroundColor ?? Colors.white,
            content: replyPopup?.replyPopupBuilder != null
                ? replyPopup!.replyPopupBuilder!(message, sendByCurrentUser)
                : ReplyPopupWidget(
                    buttonTextStyle: replyPopup?.buttonTextStyle,
                    topBorderColor: replyPopup?.topBorderColor,
                    onMoreTap: () {
                      _onChatListTap();
                      if (replyPopup?.onMoreTap != null) {
                        replyPopup?.onMoreTap!();
                      }
                    },
                    onReportTap: () {
                      _onChatListTap();
                      if (replyPopup?.onReportTap != null) {
                        replyPopup?.onReportTap!();
                      }
                    },
                    onUnsendTap: () {
                      _onChatListTap();
                      if (replyPopup?.onUnsendTap != null) {
                        replyPopup?.onUnsendTap!(message);
                      }
                    },
                    onReplyTap: () {
                      widget.assignReplyMessage(message);
                      if (featureActiveConfig?.enableReactionPopup ?? false) {
                        setState(() => showPopUp = false);
                      }
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      if (replyPopup?.onReplyTap != null) {
                        replyPopup?.onReplyTap!(message);
                      }
                    },
                    sendByCurrentUser: sendByCurrentUser,
                  ),
            padding: EdgeInsets.zero,
          ),
        )
        .closed;
  }

  void _onChatListTap() {
    if (!kIsWeb && Platform.isIOS) FocusScope.of(context).unfocus();
    setState(() => showPopUp = false);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  @override
  void dispose() {
    chatController.messageStreamController.close();
    scrollController.dispose();
    super.dispose();
  }
}
