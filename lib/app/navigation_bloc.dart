import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:prince_academy/features/booking/presentation/pages/booking/booking_screen.dart';
import 'package:prince_academy/features/home/presentation/pages/home/home.dart';
import 'package:prince_academy/features/profile/presentation/pages/profile/profile.dart';

// Events
abstract class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object> get props => [];
}

class ChangeIndex extends NavigationEvent {
  final int index;

  const ChangeIndex(this.index);

  @override
  List<Object> get props => [index];
}

// States
class NavigationState extends Equatable {
  final int currentIndex;
  final List<Widget> pages;

  const NavigationState(this.currentIndex, this.pages);

  Widget get currentPage => pages[currentIndex];

  @override
  List<Object> get props => [currentIndex];
}

// BLoC
class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc()
      : super(NavigationState(0, [
          HomeScreen(),
          BookingScreen(),
         ProfilePage(),
        ])) {
    on<ChangeIndex>((event, emit) {
      emit(NavigationState(event.index, state.pages));
    });
  }
}
