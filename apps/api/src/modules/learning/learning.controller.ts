import { Body, Controller, Get, Param, Post, UseGuards } from '@nestjs/common';
import { CurrentUser, AuthenticatedUser } from '../../common/decorators/current-user.decorator';
import { JwtAuthGuard } from '../../common/guards/jwt-auth.guard';
import { CompleteActionDto } from './dto/complete-action.dto';
import { ChatCoachDto } from './dto/chat-coach.dto';
import { SubmitQuizDto } from './dto/submit-quiz.dto';
import { LearningService } from './learning.service';

@UseGuards(JwtAuthGuard)
@Controller({ path: 'learning', version: '1' })
export class LearningController {
  constructor(private readonly learningService: LearningService) {}

  @Get('lessons')
  listLessons(@CurrentUser() user: AuthenticatedUser) {
    return this.learningService.listLessons(user.sub);
  }

  @Get('lessons/:slug')
  getLesson(@CurrentUser() user: AuthenticatedUser, @Param('slug') slug: string) {
    return this.learningService.getLesson(slug, user.sub);
  }

  @Post('quizzes/:quizId/attempts')
  submitQuiz(
    @CurrentUser() user: AuthenticatedUser,
    @Param('quizId') quizId: string,
    @Body() dto: SubmitQuizDto,
  ) {
    return this.learningService.submitQuiz(user.sub, quizId, dto);
  }

  @Post('lessons/:slug/actions')
  completeAction(
    @CurrentUser() user: AuthenticatedUser,
    @Param('slug') slug: string,
    @Body() dto: CompleteActionDto,
  ) {
    return this.learningService.completeAction(user.sub, slug, dto);
  }

  @Post('chat')
  chatCoach(@CurrentUser() user: AuthenticatedUser, @Body() dto: ChatCoachDto) {
    return this.learningService.chatCoach(user.sub, dto);
  }
}
